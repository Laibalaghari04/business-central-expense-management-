codeunit 50101 "Expense Posting"
{
    procedure PostExpenseToGL(var ExpenseHeader: Record "Expense Header")
    begin
        ExpenseHeader.TestField("Expense ID");
        ExpenseHeader.TestField("Employee No.");
        ExpenseHeader.TestField("Total Amount");

        if ExpenseHeader."Document Status" <> ExpenseHeader."Document Status"::Approved then
            Error('Only approved expenses can be posted.');

        if ExpenseHeader."GL Posting Date" = 0D then
            ExpenseHeader."GL Posting Date" := WorkDate();

        ValidatePostingPeriod(ExpenseHeader."GL Posting Date");
        ValidateEmployeeActive(ExpenseHeader."Employee No.");
        ValidateSetup();

        PostExpenseLinesWithBalancingAccount(ExpenseHeader);
        CreateEmployeeLedgerEntry(ExpenseHeader);

        ExpenseHeader."Document Status" := ExpenseHeader."Document Status"::Posted;
        ExpenseHeader.Modify(false);
        ExpenseHeader.LogAction('POSTED', ExpenseHeader."Total Amount");
    end;

    local procedure PostExpenseLinesWithBalancingAccount(ExpenseHeader: Record "Expense Header")
    var
        ExpenseLine: Record "Expense Line";
        ExpenseSetup: Record "Employee Expense Setup";
        LineNo: Integer;
        LineAmount: Decimal;
    begin
        if not ExpenseSetup.FindFirst() then
            Error('Employee Expense Setup is missing.');

        ExpenseSetup.TestField("GL Account Reimbursement");

        ExpenseLine.SetRange("Expense ID", ExpenseHeader."Expense ID");

        if not ExpenseLine.FindSet() then
            Error('No expense lines found for expense %1.', ExpenseHeader."Expense ID");

        LineNo := 10000;

        repeat
            ExpenseLine.TestField("GL Account");
            ExpenseLine.TestField("Net Amount");

            ValidateGLAccount(ExpenseLine."GL Account");
            ValidateGLAccount(ExpenseSetup."GL Account Reimbursement");

            LineAmount := GetLinePostingAmount(ExpenseLine);

            if LineAmount <= 0 then
                Error('Posting amount must be greater than zero for line %1.', ExpenseLine."Line No.");

            PostBalancedGenJournalLine(
                ExpenseHeader."GL Posting Date",
                ExpenseHeader."Expense ID",
                LineNo,
                ExpenseLine."GL Account",
                ExpenseSetup."GL Account Reimbursement",
                LineAmount,
                CopyStr(StrSubstNo('Expense %1 - %2', ExpenseHeader."Expense ID", ExpenseLine.Description), 1, 100)
            );

            LineNo += 10000;
        until ExpenseLine.Next() = 0;
    end;

    local procedure PostBalancedGenJournalLine(
        PostingDate: Date;
        DocumentNo: Code[20];
        LineNo: Integer;
        ExpenseAccountNo: Code[20];
        LiabilityAccountNo: Code[20];
        Amount: Decimal;
        Description: Text[100])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        GenJournalLine.Init();

        GenJournalLine."Line No." := LineNo;
        GenJournalLine."Posting Date" := PostingDate;
        GenJournalLine."Document Date" := PostingDate;
        GenJournalLine."Document No." := DocumentNo;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::" ";

        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine.Validate("Account No.", ExpenseAccountNo);

        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";
        GenJournalLine.Validate("Bal. Account No.", LiabilityAccountNo);

        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Description := Description;
        GenJournalLine."Source Code" := 'GENJNL';

        GenJnlPostLine.RunWithCheck(GenJournalLine);
    end;

    local procedure CreateEmployeeLedgerEntry(ExpenseHeader: Record "Expense Header")
    var
        EmployeeLedgerEntryExt: Record "Employee  Entry LedgerExt";
        AmountToPay: Decimal;
    begin
        AmountToPay := CalcPostingTotalAmount(ExpenseHeader);

        EmployeeLedgerEntryExt.Init();
        EmployeeLedgerEntryExt."Entry No." := GetNextEmployeeLedgerEntryNo();
        EmployeeLedgerEntryExt."Employee No." := ExpenseHeader."Employee No.";
        EmployeeLedgerEntryExt."Entry Type" := EmployeeLedgerEntryExt."Entry Type"::Expense;
        EmployeeLedgerEntryExt."Document No." := ExpenseHeader."Expense ID";
        EmployeeLedgerEntryExt."Posting Date" := ExpenseHeader."GL Posting Date";
        EmployeeLedgerEntryExt."Due Date" := CalcDate('<+30D>', ExpenseHeader."GL Posting Date");
        EmployeeLedgerEntryExt.Amount := AmountToPay;
        EmployeeLedgerEntryExt."Remaining Amount" := AmountToPay;
        EmployeeLedgerEntryExt."Expense ID" := ExpenseHeader."Expense ID";
        EmployeeLedgerEntryExt."Approval Status" := 'APPROVED';
        EmployeeLedgerEntryExt.Open := true;
        EmployeeLedgerEntryExt.Insert(true);
    end;

    local procedure ValidateSetup()
    var
        ExpenseSetup: Record "Employee Expense Setup";
    begin
        if not ExpenseSetup.FindFirst() then
            Error('Employee Expense Setup is missing.');

        ExpenseSetup.TestField("GL Account Reimbursement");
    end;

    local procedure ValidatePostingPeriod(PostingDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if PostingDate = 0D then
            Error('Posting Date cannot be blank.');

        GeneralLedgerSetup.Get();

        if GeneralLedgerSetup."Allow Posting From" <> 0D then
            if PostingDate < GeneralLedgerSetup."Allow Posting From" then
                Error(
                    'Posting Date %1 is before allowed posting date %2.',
                    PostingDate,
                    GeneralLedgerSetup."Allow Posting From"
                );

        if GeneralLedgerSetup."Allow Posting To" <> 0D then
            if PostingDate > GeneralLedgerSetup."Allow Posting To" then
                Error(
                    'Posting Date %1 is after allowed posting date %2.',
                    PostingDate,
                    GeneralLedgerSetup."Allow Posting To"
                );
    end;

    local procedure ValidateEmployeeActive(EmployeeNo: Code[20])
    var
        Employee: Record Employee;
    begin
        Employee.Get(EmployeeNo);

        if Employee.Status <> Employee.Status::Active then
            Error('Employee %1 is not active.', EmployeeNo);
    end;

    local procedure ValidateGLAccount(GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);

        if GLAccount."Account Type" <> GLAccount."Account Type"::Posting then
            Error('G/L Account %1 is not a posting account.', GLAccountNo);

        if GLAccount.Blocked then
            Error('G/L Account %1 is blocked.', GLAccountNo);

        if not GLAccount."Direct Posting" then
            Error('G/L Account %1 does not allow direct posting.', GLAccountNo);
    end;

    local procedure GetLinePostingAmount(ExpenseLine: Record "Expense Line"): Decimal
    begin
        if ExpenseLine."Approved Line Amount" > 0 then
            exit(ExpenseLine."Approved Line Amount");

        exit(ExpenseLine."Net Amount");
    end;

    local procedure CalcPostingTotalAmount(ExpenseHeader: Record "Expense Header"): Decimal
    var
        ExpenseLine: Record "Expense Line";
        TotalAmount: Decimal;
    begin
        ExpenseLine.SetRange("Expense ID", ExpenseHeader."Expense ID");

        if ExpenseLine.FindSet() then
            repeat
                TotalAmount += GetLinePostingAmount(ExpenseLine);
            until ExpenseLine.Next() = 0;

        exit(TotalAmount);
    end;

    local procedure GetNextEmployeeLedgerEntryNo(): Integer
    var
        EmployeeLedgerEntryExt: Record "Employee  Entry LedgerExt";
    begin
        if EmployeeLedgerEntryExt.FindLast() then
            exit(EmployeeLedgerEntryExt."Entry No." + 1);

        exit(1);
    end;

    procedure LogPostingError(ExpenseId: Code[20]; ErrorMsg: Text)
    var
        PostingErrorLog: Record "Posting Error Log";
    begin
        PostingErrorLog.Init();
        PostingErrorLog."Document Type" := 'EXPENSE';
        PostingErrorLog."Document No." := ExpenseId;
        PostingErrorLog."Error Message" := CopyStr(ErrorMsg, 1, MaxStrLen(PostingErrorLog."Error Message"));
        PostingErrorLog."Error DateTime" := CurrentDateTime();
        PostingErrorLog."User ID" := CopyStr(UserId(), 1, MaxStrLen(PostingErrorLog."User ID"));
        PostingErrorLog.Resolved := false;
        PostingErrorLog.Insert(true);
    end;

    procedure ReverseExpensePosting(var ExpenseHeader: Record "Expense Header")
    var
        GLEntry: Record "G/L Entry";
        ExpenseSetup: Record "Employee Expense Setup";
        ReversalDocNo: Code[20];
        LineNo: Integer;
    begin
        if ExpenseHeader."Document Status" <> ExpenseHeader."Document Status"::Posted then
            Error('Only posted expenses can be reversed.');

        if not ExpenseSetup.FindFirst() then
            Error('Employee Expense Setup is missing.');

        ExpenseSetup.TestField("GL Account Reimbursement");

        GLEntry.SetRange("Document No.", ExpenseHeader."Expense ID");

        if not GLEntry.FindSet() then
            Error('No G/L entries found for expense %1.', ExpenseHeader."Expense ID");

        ReversalDocNo := CopyStr(StrSubstNo('REV-%1', ExpenseHeader."Expense ID"), 1, MaxStrLen(ReversalDocNo));
        LineNo := 10000;

        repeat
            PostBalancedGenJournalLine(
                WorkDate(),
                ReversalDocNo,
                LineNo,
                GLEntry."G/L Account No.",
                ExpenseSetup."GL Account Reimbursement",
                -GLEntry.Amount,
                CopyStr(StrSubstNo('Reversal of %1', ExpenseHeader."Expense ID"), 1, 100)
            );

            LineNo += 10000;
        until GLEntry.Next() = 0;

        ExpenseHeader."Document Status" := ExpenseHeader."Document Status"::Cancelled;
        ExpenseHeader.Modify(false);
        ExpenseHeader.LogAction('REVERSED', ExpenseHeader."Total Amount");
    end;
}