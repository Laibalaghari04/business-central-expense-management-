page 50108 "Expense User Setup"
{
    ApplicationArea = All;
    Caption = 'Expense User Setup';
    PageType = List;
    SourceTable = "Expense User Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                }

                field("Can Submit"; Rec."Can Submit")
                {
                    ApplicationArea = All;
                }

                field("Can Approve"; Rec."Can Approve")
                {
                    ApplicationArea = All;
                }

                field("Can Post"; Rec."Can Post")
                {
                    ApplicationArea = All;
                }

                field("Is Active"; Rec."Is Active")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}