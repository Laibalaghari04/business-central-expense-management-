table 50105 "Expense Log"
{
    DataClassification = CustomerContent;
    Caption = 'Expense Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }

        field(2; "Expense ID"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Expense ID';
            TableRelation = "Expense Header";
        }

        field(3; "Action Type"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Action Type';
        }

        field(4; "User ID"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'User ID';
        }

        field(5; "Action DateTime"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Action DateTime';
        }

        field(6; Amount; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Amount';
            DecimalPlaces = 2 : 2;
        }

        field(7; "Employee No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Employee No.';
            TableRelation = Employee;
        }

        field(8; Description; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(ExpenseDate; "Expense ID", "Action DateTime") { }
    }
}
