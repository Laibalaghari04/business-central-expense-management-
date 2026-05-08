table 50107 "Employee  Entry LedgerExt"
{
    DataClassification = CustomerContent;
    Caption = 'Employee Ledger Entry Ext';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
        }

        field(2; "Employee No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Employee No.';
            TableRelation = Employee;
        }

        field(3; "Entry Type"; Enum "Employee Ledger Entry Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Entry Type';
        }

        field(4; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Document No.';
        }

        field(5; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Posting Date';
        }

        field(6; "Due Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Due Date';
        }

        field(7; Amount; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Amount';
            DecimalPlaces = 2 : 2;
        }

        field(8; "Remaining Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Remaining Amount';
            DecimalPlaces = 2 : 2;
        }

        field(9; "Expense ID"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Expense ID';
            TableRelation = "Expense Header";
        }

        field(10; "Approval Status"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Approval Status';
        }

        field(11; Open; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Open';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(EmployeeDate; "Employee No.", "Posting Date") { }
        key(Expense; "Expense ID") { }
    }
}

enum 50104 "Employee Ledger Entry Type"
{
    Extensible = true;

    value(0; Salary) { Caption = 'Salary'; }
    value(1; Advance) { Caption = 'Advance'; }
    value(2; Expense) { Caption = 'Expense'; }
    value(3; Loan) { Caption = 'Loan'; }
}
