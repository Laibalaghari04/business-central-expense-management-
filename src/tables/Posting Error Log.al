// ============================================================================
// TABLE 50106: POSTING ERROR LOG
// Purpose: Track posting errors for finance review
// ============================================================================

table 50106 "Posting Error Log"
{
    DataClassification = CustomerContent;
    Caption = 'Posting Error Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }

        field(2; "Document Type"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Document Type';
        }

        field(3; "Document No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Document No.';
        }

        field(4; "Error Message"; Text[1024])
        {
            DataClassification = CustomerContent;
            Caption = 'Error Message';
        }

        field(5; "Error DateTime"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Error DateTime';
        }

        field(6; "User ID"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'User ID';
        }

        field(7; Resolved; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Resolved';
        }

        field(8; "Resolution Notes"; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Resolution Notes';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(DocumentDate; "Document No.", "Error DateTime") { }
    }
}
