
table 50104 "Employee Approval Hierarchy"
{
    DataClassification = CustomerContent;
    Caption = 'Employee Approval Hierarchy';

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Employee No.';
            TableRelation = Employee;
        }

        field(2; "Approval Sequence"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Approval Sequence';
            MinValue = 1;
        }

        field(3; "Approving Employee No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Approving Employee No.';
            TableRelation = Employee;
        }

        field(4; "Approval Type"; Enum "Approval Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Approval Type';
        }

        field(5; "Delegate To Employee No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Delegate To Employee No.';
            TableRelation = Employee;
        }

        field(6; "Delegation Start Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Delegation Start Date';
        }

        field(7; "Delegation End Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Delegation End Date';
        }

        field(8; "Is Active"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Active';
            InitValue = true;
        }

        field(9; Comments; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Comments';
        }
    }

    keys
    {
        key(PK; "Employee No.", "Approval Sequence") { Clustered = true; }
        key(Approver; "Approving Employee No.") { }
    }

    procedure GetCurrentApprover(): Code[20]
    begin
        if ("Delegate To Employee No." <> '') and (Today() >= "Delegation Start Date") and
           (("Delegation End Date" = 0D) or (Today() <= "Delegation End Date")) then
            exit("Delegate To Employee No.");

        exit("Approving Employee No.");
    end;
}

enum 50103 "Approval Type"
{
    Extensible = true;

    value(0; Manager) { Caption = 'Manager'; }
    value(1; Director) { Caption = 'Director'; }
    value(2; Finance) { Caption = 'Finance'; }
    value(3; CFO) { Caption = 'CFO'; }
}
