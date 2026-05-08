
table 50100 "Expense Header"
{
    DataClassification = CustomerContent;
    Caption = 'Expense Header';

    fields
    {
        field(1; "Expense ID"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Expense ID';

            trigger OnValidate()
            begin
                if "Expense ID" <> '' then
                    if not ExpenseIdFormatIsValid("Expense ID") then
                        Error('Expense ID must follow this format: EXP-YYYY-NNNNN.');
            end;
        }

        field(2; "Employee No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            var
                Employee: Record Employee;
            begin
                if "Employee No." = '' then begin
                    Clear("Employee Name");
                    Clear("Cost Center");
                    exit;
                end;

                Employee.Get("Employee No.");

                if Employee.Status <> Employee.Status::Active then
                    Error('Only active employees can submit expenses.');

                "Employee Name" := CopyStr(DelChr(Employee."First Name" + ' ' + Employee."Last Name", '<>', ' '), 1, MaxStrLen("Employee Name"));
                "Cost Center" := Employee."Global Dimension 1 Code";
            end;
        }

        field(3; "Employee Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Employee Name';
            Editable = false;
        }

        field(4; "Expense Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Expense Date';

            trigger OnValidate()
            begin
                if "Expense Date" = 0D then
                    exit;

                if "Expense Date" > WorkDate() then
                    Error('Expense date cannot be in the future.');

                if (WorkDate() - "Expense Date") > 90 then
                    Message('Warning: this expense is more than 90 days old.');
            end;
        }

        field(5; "Submitted Date"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Submitted Date';
            Editable = false;
        }

        field(6; "Document Status"; Enum "Expense Doc Status")
        {
            DataClassification = CustomerContent;
            Caption = 'Document Status';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateStatusTransition();
            end;
        }

        field(7; "Approval Status"; Enum "Expense Approval Status")
        {
            DataClassification = CustomerContent;
            Caption = 'Approval Status';
            Editable = false;
        }

        field(8; "Total Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Total Amount';
            Editable = false;
            DecimalPlaces = 2 : 2;

            trigger OnValidate()
            begin
                if "Total Amount" < 0 then
                    Error('Total amount cannot be negative.');
            end;
        }

        field(9; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Currency Code';
            TableRelation = Currency;
        }

        field(10; "Approved By"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Approved By';
            Editable = false;
        }

        field(11; "Approved Date"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Approved Date';
            Editable = false;
        }

        field(12; "Rejection Reason"; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Rejection Reason';
        }

        field(13; "GL Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'G/L Posting Date';
        }

        field(14; "Check No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Check No.';
        }

        field(15; Notes; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Notes';
        }

        field(16; "Cost Center"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Cost Center';
            Editable = false;
        }

        field(17; "Created By"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Created By';
            Editable = false;
        }

        field(18; "Created DateTime"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Created DateTime';
            Editable = false;
        }

        field(19; "Modified By"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Modified By';
            Editable = false;
        }

        field(20; "Modified DateTime"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Modified DateTime';
            Editable = false;
        }

        field(21; "Next Approver"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Next Approver';
            TableRelation = Employee;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Expense ID") { Clustered = true; }
        key(EmployeeDate; "Employee No.", "Submitted Date") { }
        key(Status; "Document Status", "Approval Status") { }
        key(PostingDate; "GL Posting Date") { }
    }

    trigger OnInsert()
    begin
        if "Expense ID" = '' then
            "Expense ID" := GenerateExpenseId();

        "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        "Created DateTime" := CurrentDateTime();
        "Modified By" := CopyStr(UserId(), 1, MaxStrLen("Modified By"));
        "Modified DateTime" := CurrentDateTime();
        "Document Status" := "Document Status"::Draft;
        "Approval Status" := "Approval Status"::Pending;
    end;

    trigger OnModify()
    begin
        if xRec."Document Status" = xRec."Document Status"::Posted then
            Error('Cannot modify a posted expense.');

        if (xRec."Document Status" = xRec."Document Status"::Posted) then
            if not ("Document Status" in ["Document Status"::Paid, "Document Status"::Cancelled]) then
                Error('Posted expenses can only be marked as Paid or Cancelled by reversal.');

        "Modified By" := CopyStr(UserId(), 1, MaxStrLen("Modified By"));
        "Modified DateTime" := CurrentDateTime();
    end;

    trigger OnDelete()
    var
        ExpenseLine: Record "Expense Line";
    begin
        if "Document Status" <> "Document Status"::Draft then
            Error('Only draft expenses can be deleted.');

        ExpenseLine.SetRange("Expense ID", "Expense ID");
        ExpenseLine.DeleteAll(true);
    end;

    local procedure ValidateStatusTransition()
    var
        IsAllowed: Boolean;
    begin
        if xRec."Expense ID" = '' then
            exit;

        if xRec."Document Status" = "Document Status" then
            exit;

        case xRec."Document Status" of
            xRec."Document Status"::Draft:
                IsAllowed := "Document Status" in ["Document Status"::Submitted, "Document Status"::Cancelled];
            xRec."Document Status"::Submitted:
                IsAllowed := "Document Status" in ["Document Status"::Approved, "Document Status"::Draft, "Document Status"::Cancelled];
            xRec."Document Status"::Approved:
                IsAllowed := "Document Status" in ["Document Status"::Posted, "Document Status"::Cancelled];
            xRec."Document Status"::Posted:
                IsAllowed := "Document Status" in ["Document Status"::Paid, "Document Status"::Cancelled];
            else
                IsAllowed := false;
        end;

        if not IsAllowed then
            Error('Invalid status change from %1 to %2.', xRec."Document Status", "Document Status");
    end;

    local procedure ExpenseIdFormatIsValid(ExpenseId: Code[20]): Boolean
    var
        YearPart: Integer;
        NoPart: Integer;
    begin
        if StrLen(ExpenseId) <> 14 then
            exit(false);

        if CopyStr(ExpenseId, 1, 4) <> 'EXP-' then
            exit(false);

        if CopyStr(ExpenseId, 9, 1) <> '-' then
            exit(false);

        if not Evaluate(YearPart, CopyStr(ExpenseId, 5, 4)) then
            exit(false);

        if not Evaluate(NoPart, CopyStr(ExpenseId, 10, 5)) then
            exit(false);

        exit(true);
    end;

    local procedure GenerateExpenseId(): Code[20]
    var
        ExpenseHeader: Record "Expense Header";
        LastNo: Integer;
        NewNo: Integer;
        CurrentYear: Integer;
        Prefix: Code[9];
    begin
        CurrentYear := Date2DMY(WorkDate(), 3);
        Prefix := StrSubstNo('EXP-%1-', CurrentYear);

        ExpenseHeader.SetFilter("Expense ID", '%1*', Prefix);
        if ExpenseHeader.FindLast() then
            LastNo := GetNumberFromExpenseId(ExpenseHeader."Expense ID");

        NewNo := LastNo + 1;
        exit(CopyStr(Prefix + LeftPadNo(NewNo, 5), 1, 20));
    end;

    local procedure GetNumberFromExpenseId(ExpenseId: Code[20]): Integer
    var
        NumberPart: Integer;
    begin
        if not Evaluate(NumberPart, CopyStr(ExpenseId, 10, 5)) then
            NumberPart := 0;
        exit(NumberPart);
    end;

    local procedure LeftPadNo(NumberToPad: Integer; Length: Integer): Text
    var
        PaddedText: Text;
    begin
        PaddedText := Format(NumberToPad);
        while StrLen(PaddedText) < Length do
            PaddedText := '0' + PaddedText;
        exit(PaddedText);
    end;

    procedure CalcTotalAmount()
    var
        ExpenseLine: Record "Expense Line";
        Total: Decimal;
    begin
        ExpenseLine.SetRange("Expense ID", "Expense ID");
        if ExpenseLine.FindSet() then
            repeat
                Total += ExpenseLine."Net Amount";
            until ExpenseLine.Next() = 0;

        "Total Amount" := Total;
    end;

    procedure SubmitForApproval()
    var
        ExpenseLine: Record "Expense Line";
        ExpenseSetup: Record "Employee Expense Setup";
    begin
        if not CurrentUserCanSubmit() then
            Error('You do not have permission to submit expenses.');
        TestField("Employee No.");
        TestField("Expense Date");

        if "Document Status" <> "Document Status"::Draft then
            Error('Only draft expenses can be submitted.');

        ExpenseLine.SetRange("Expense ID", "Expense ID");
        if not ExpenseLine.FindSet() then
            Error('Expense must have at least one line.');

        repeat
            ExpenseLine.ValidateLine();
        until ExpenseLine.Next() = 0;

        CalcTotalAmount();
        if "Total Amount" <= 0 then
            Error('Total amount must be greater than zero.');

        if not ExpenseSetup.FindFirst() then
            Error('Employee Expense Setup is missing. Please create setup first.');

        "Submitted Date" := CurrentDateTime();
        "Approval Status" := "Approval Status"::Pending;
        "Document Status" := "Document Status"::Submitted;

        if "Total Amount" < ExpenseSetup."Approval Required Above" then begin
            "Approval Status" := "Approval Status"::Approved;
            "Approved By" := 'SYSTEM';
            "Approved Date" := CurrentDateTime();
            "Document Status" := "Document Status"::Approved;
            Clear("Next Approver");
        end else
            FindAndAssignApprover();

        Modify(true);
        LogAction('SUBMITTED', "Total Amount");
    end;

    procedure FindAndAssignApprover()
    var
        ApprovalHierarchy: Record "Employee Approval Hierarchy";
    begin
        ApprovalHierarchy.SetRange("Employee No.", "Employee No.");
        ApprovalHierarchy.SetRange("Is Active", true);
        ApprovalHierarchy.SetCurrentKey("Employee No.", "Approval Sequence");

        if ApprovalHierarchy.FindFirst() then
            "Next Approver" := ApprovalHierarchy.GetCurrentApprover()
        else
            Error('No active approver is configured for employee %1.', "Employee No.");
    end;

    procedure ApproveExpense()
    begin
        if not CurrentUserCanApprove() then
            Error('You do not have permission to approve expenses.');
        if "Document Status" <> "Document Status"::Submitted then
            Error('Only submitted expenses can be approved.');

        "Approved By" := CopyStr(UserId(), 1, MaxStrLen("Approved By"));
        "Approved Date" := CurrentDateTime();
        "Approval Status" := "Approval Status"::Approved;
        "Document Status" := "Document Status"::Approved;
        Clear("Next Approver");

        Modify(true);
        LogAction('APPROVED', "Total Amount");
    end;

    procedure RejectExpense(RejectionReasonText: Text[500])
    begin
        if not CurrentUserCanApprove() then
            Error('You do not have permission to reject expenses.');
        if "Document Status" <> "Document Status"::Submitted then
            Error('Only submitted expenses can be rejected.');

        if RejectionReasonText = '' then
            Error('Rejection reason is mandatory.');

        "Rejection Reason" := RejectionReasonText;
        "Approval Status" := "Approval Status"::Rejected;
        "Document Status" := "Document Status"::Draft;
        Clear("Next Approver");

        Modify(true);
        LogAction('REJECTED', 0);
    end;

    procedure PostToGL()
    var
        ExpensePosting: Codeunit "Expense Posting";
    begin
        if not CurrentUserCanPost() then
            Error('You do not have permission to post expenses.');
        if "Document Status" <> "Document Status"::Approved then
            Error('Only approved expenses can be posted.');
        if "GL Posting Date" = 0D then
            "GL Posting Date" := WorkDate();


        ExpensePosting.PostExpenseToGL(Rec);

        "Document Status" := "Document Status"::Posted;
        "GL Posting Date" := WorkDate();
        Modify(false);
        LogAction('POSTED', "Total Amount");
    end;

    procedure MarkAsPaid(CheckNo: Code[20])
    begin
        if "Document Status" <> "Document Status"::Posted then
            Error('Only posted expenses can be marked as paid.');

        "Document Status" := "Document Status"::Paid;
        "Check No." := CheckNo;
        Modify(true);
        LogAction('PAID', "Total Amount");
    end;

    procedure LogAction(ActionType: Code[20]; Amount: Decimal)
    var
        ExpenseLog: Record "Expense Log";
    begin
        ExpenseLog.Init();
        ExpenseLog."Expense ID" := "Expense ID";
        ExpenseLog."Action Type" := ActionType;
        ExpenseLog."User ID" := CopyStr(UserId(), 1, MaxStrLen(ExpenseLog."User ID"));
        ExpenseLog."Action DateTime" := CurrentDateTime();
        ExpenseLog.Amount := Amount;
        ExpenseLog."Employee No." := "Employee No.";
        ExpenseLog.Insert(true);
    end;

    procedure CurrentUserCanSubmit(): Boolean
    var
        ExpenseUserSetup: Record "Expense User Setup";
    begin
        if ExpenseUserSetup.Get(CopyStr(UserId(), 1, MaxStrLen(ExpenseUserSetup."User ID"))) then
            exit(ExpenseUserSetup."Is Active" and ExpenseUserSetup."Can Submit");

        exit(false);
    end;

    procedure CurrentUserCanApprove(): Boolean
    var
        ExpenseUserSetup: Record "Expense User Setup";
    begin
        if ExpenseUserSetup.Get(CopyStr(UserId(), 1, MaxStrLen(ExpenseUserSetup."User ID"))) then
            exit(ExpenseUserSetup."Is Active" and ExpenseUserSetup."Can Approve");

        exit(false);
    end;

    procedure CurrentUserCanPost(): Boolean
    var
        ExpenseUserSetup: Record "Expense User Setup";
    begin
        if ExpenseUserSetup.Get(CopyStr(UserId(), 1, MaxStrLen(ExpenseUserSetup."User ID"))) then
            exit(ExpenseUserSetup."Is Active" and ExpenseUserSetup."Can Post");

        exit(false);
    end;
}


enum 50100 "Expense Doc Status"
{
    Extensible = true;

    value(0; Draft) { Caption = 'Draft'; }
    value(1; Submitted) { Caption = 'Submitted'; }
    value(2; Approved) { Caption = 'Approved'; }
    value(3; Posted) { Caption = 'Posted'; }
    value(4; Paid) { Caption = 'Paid'; }
    value(5; Cancelled) { Caption = 'Cancelled'; }
}

enum 50101 "Expense Approval Status"
{
    Extensible = true;

    value(0; Pending) { Caption = 'Pending'; }
    value(1; Approved) { Caption = 'Approved'; }
    value(2; Rejected) { Caption = 'Rejected'; }
    value(3; Cancelled) { Caption = 'Cancelled'; }
}
