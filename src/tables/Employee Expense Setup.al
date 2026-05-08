
table 50103 "Employee Expense Setup"
{
    DataClassification = CustomerContent;
    Caption = 'Employee Expense Setup';

    fields
    {
        field(1; "Setup ID"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Setup ID';
            InitValue = 'DEFAULT';
        }

        field(2; "Approval Required Above"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Approval Required Above';
            DecimalPlaces = 2 : 2;
        }

        field(3; "Manager Approval Limit"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Manager Approval Limit';
            DecimalPlaces = 2 : 2;
        }

        field(4; "Director Approval Limit"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Director Approval Limit';
            DecimalPlaces = 2 : 2;
        }

        field(5; "CFO Approval Required"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'CFO Approval Required';
        }

        field(6; "Require Receipts Above"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Require Receipts Above';
            DecimalPlaces = 2 : 2;
        }

        field(7; "Days To Submit After Expense"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Days To Submit After Expense';
            MinValue = 1;
            MaxValue = 365;
        }

        field(8; "Allow Currency Differences"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Allow Currency Differences';
        }

        field(9; "Reimbursement Method"; Enum "Reimbursement Method")
        {
            DataClassification = CustomerContent;
            Caption = 'Reimbursement Method';
        }

        field(10; "GL Account Reimbursement"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'G/L Account Reimbursement';
            TableRelation = "G/L Account" where("Account Type" = const(Posting));
        }

        field(11; "Default Payment Terms"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Default Payment Terms';
            TableRelation = "Payment Terms";
        }

        field(12; "Journal Template Name"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }

        field(13; "Journal Batch Name"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
    }

    keys
    {
        key(PK; "Setup ID") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if "Setup ID" = '' then
            "Setup ID" := 'DEFAULT';
    end;
}

enum 50102 "Reimbursement Method"
{
    Extensible = true;

    value(0; "Bank Transfer") { Caption = 'Bank Transfer'; }
    value(1; Check) { Caption = 'Check'; }
    value(2; Payroll) { Caption = 'Payroll'; }
}
