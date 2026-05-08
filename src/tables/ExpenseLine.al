
table 50101 "Expense Line"
{
    DataClassification = CustomerContent;
    Caption = 'Expense Line';

    fields
    {
        field(1; "Expense ID"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Expense ID';
            TableRelation = "Expense Header";
        }

        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }

        field(3; "Expense Category"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Expense Category';
            TableRelation = "Expense Category" where("Is Active" = const(true));

            trigger OnValidate()
            var
                ExpenseCategory: Record "Expense Category";
            begin
                if "Expense Category" = '' then
                    exit;

                ExpenseCategory.Get("Expense Category");
                if not ExpenseCategory."Is Active" then
                    Error('Expense category %1 is not active.', "Expense Category");

                Validate("GL Account", ExpenseCategory."GL Account No.");
                Validate("Is Taxable", ExpenseCategory."Is Taxable");
                Validate("Tax Rate", ExpenseCategory."Default Tax Rate");

                if Description = '' then
                    Description := ExpenseCategory."Category Name";
            end;
        }

        field(4; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }

        field(5; "Expense Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Expense Amount';
            DecimalPlaces = 2 : 2;

            trigger OnValidate()
            begin
                if "Expense Amount" < 0 then
                    Error('Expense amount cannot be negative.');

                CalculateTaxAndNet();
            end;
        }

        field(6; "Tax Rate"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Tax Rate';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;

            trigger OnValidate()
            begin
                CalculateTaxAndNet();
            end;
        }

        field(7; "Tax Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Tax Amount';
            Editable = false;
            DecimalPlaces = 2 : 2;
        }

        field(8; "Net Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Net Amount';
            Editable = false;
            DecimalPlaces = 2 : 2;
        }

        field(9; "Expense Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Expense Date';

            trigger OnValidate()
            begin
                if "Expense Date" = 0D then
                    exit;

                if "Expense Date" > WorkDate() then
                    Error('Expense date cannot be in the future.');
            end;
        }

        field(10; Justification; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Justification';
        }

        field(11; "GL Account"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'G/L Account';
            TableRelation = "G/L Account" where("Account Type" = const(Posting));

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if "GL Account" = '' then
                    exit;

                GLAccount.Get("GL Account");
                if GLAccount."Account Type" <> GLAccount."Account Type"::Posting then
                    Error('G/L Account %1 is not a posting account.', "GL Account");

                if GLAccount.Blocked then
                    Error('G/L Account %1 is blocked.', "GL Account");

                if not GLAccount."Direct Posting" then
                    Error('G/L Account %1 does not allow direct posting.', "GL Account");
            end;
        }

        field(12; "Expense Type Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Expense Type Code';
        }

        field(13; "Document Attachment No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Document Attachment No.';
        }

        field(14; "Approved Line Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Approved Line Amount';
            DecimalPlaces = 2 : 2;

            trigger OnValidate()
            begin
                if "Approved Line Amount" < 0 then
                    Error('Approved line amount cannot be negative.');

                if ("Approved Line Amount" > 0) and ("Approved Line Amount" > "Net Amount") then
                    Error('Approved line amount cannot exceed net amount.');
            end;
        }

        field(15; "Is Taxable"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Taxable';

            trigger OnValidate()
            begin
                CalculateTaxAndNet();
            end;
        }

        field(16; "Created DateTime"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Created DateTime';
            Editable = false;
        }

        field(17; "Modified DateTime"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Modified DateTime';
            Editable = false;
        }

        field(18; "Receipt Required"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Receipt Required';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Expense ID", "Line No.") { Clustered = true; }
        key(Category; "Expense Category") { }
        key(GLAccount; "GL Account") { }
    }

    trigger OnInsert()
    begin
        if "Line No." = 0 then
            "Line No." := GetNextLineNo();

        "Created DateTime" := CurrentDateTime();
        "Modified DateTime" := CurrentDateTime();
        CheckParentEditable();
        CalculateTaxAndNet();
    end;

    trigger OnModify()
    begin
        CheckParentEditable();
        "Modified DateTime" := CurrentDateTime();
    end;

    trigger OnDelete()
    begin
        CheckParentEditable();
        UpdateHeaderTotal();
    end;

    local procedure GetNextLineNo(): Integer
    var
        ExpenseLine: Record "Expense Line";
    begin
        ExpenseLine.SetRange("Expense ID", "Expense ID");
        if ExpenseLine.FindLast() then
            exit(ExpenseLine."Line No." + 10000);

        exit(10000);
    end;

    local procedure CheckParentEditable()
    var
        ExpenseHeader: Record "Expense Header";
    begin
        if "Expense ID" = '' then
            exit;

        ExpenseHeader.Get("Expense ID");
        if ExpenseHeader."Document Status" <> ExpenseHeader."Document Status"::Draft then
            Error('Expense lines can only be changed while the expense header is in Draft status.');
    end;

    local procedure CalculateTaxAndNet()
    begin
        if "Is Taxable" and ("Tax Rate" > 0) then
            "Tax Amount" := Round(("Expense Amount" * "Tax Rate") / 100, 0.01)
        else
            "Tax Amount" := 0;

        "Net Amount" := "Expense Amount" - "Tax Amount";
        UpdateHeaderTotal();
    end;

    local procedure UpdateHeaderTotal()
    var
        ExpenseHeader: Record "Expense Header";
    begin
        if "Expense ID" = '' then
            exit;

        if ExpenseHeader.Get("Expense ID") then begin
            ExpenseHeader.CalcTotalAmount();
            ExpenseHeader.Modify(true);
        end;
    end;

    procedure ValidateLine()
    var
        ExpenseSetup: Record "Employee Expense Setup";
        ExpenseCategory: Record "Expense Category";
    begin
        TestField("Expense ID");
        TestField("Expense Category");
        TestField(Description);
        TestField("Expense Amount");
        TestField("Net Amount");
        TestField("GL Account");
        TestField("Expense Date");

        if ExpenseCategory.Get("Expense Category") then
            if (ExpenseCategory."Max Amount Per Claim" > 0) and ("Expense Amount" > ExpenseCategory."Max Amount Per Claim") then
                Error('Amount %1 exceeds the maximum allowed amount %2 for category %3.', "Expense Amount", ExpenseCategory."Max Amount Per Claim", "Expense Category");

        if ExpenseSetup.FindFirst() then begin
            "Receipt Required" := "Expense Amount" >= ExpenseSetup."Require Receipts Above";
            Modify(false);
        end;
    end;
}
