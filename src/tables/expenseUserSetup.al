table 50108 "Expense User Setup"
{
    DataClassification = CustomerContent;
    Caption = 'Expense User Setup';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'User ID';
        }

        field(2; "Can Submit"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Can Submit';
        }

        field(3; "Can Approve"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Can Approve';
        }

        field(4; "Can Post"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Can Post to G/L';
        }

        field(5; "Is Active"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Active';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "User ID")
        {
            Clustered = true;
        }
    }
}