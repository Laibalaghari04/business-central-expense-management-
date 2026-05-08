table 50102 "Expense Category"
{
    DataClassification = CustomerContent;
    Caption = 'Expense Category';

    fields
    {
        field(1; "Category Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Category Code';
        }

        field(2; "Category Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Category Name';
        }

        field(3; "GL Account No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account" where("Account Type" = const(Posting));

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if "GL Account No." = '' then
                    exit;

                GLAccount.Get("GL Account No.");
                if GLAccount.Blocked then
                    Error('G/L Account %1 is blocked.', "GL Account No.");

                if not GLAccount."Direct Posting" then
                    Error('G/L Account %1 does not allow direct posting.', "GL Account No.");
            end;
        }

        field(4; "Is Taxable"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Taxable';
        }

        field(5; "Default Tax Rate"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Default Tax Rate';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 100;
        }

        field(6; "Requires Approval Above"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Requires Approval Above';
            DecimalPlaces = 2 : 2;
        }

        field(7; "Max Amount Per Claim"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Max Amount Per Claim';
            DecimalPlaces = 2 : 2;
        }

        field(8; "Max Amount Per Day"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Max Amount Per Day';
            DecimalPlaces = 2 : 2;
        }

        field(9; "Is Active"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Active';
            InitValue = true;
        }

        field(10; Description; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Category Code") { Clustered = true; }
    }
}
