page 50100 "Expense List"
{
    ApplicationArea = All;
    Caption = 'Expense Claims';
    PageType = List;
    SourceTable = "Expense Header";
    UsageCategory = Lists;
    CardPageId = "Expense Card";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Expense ID"; Rec."Expense ID") { ApplicationArea = All; }
                field("Employee No."; Rec."Employee No.") { ApplicationArea = All; }
                field("Employee Name"; Rec."Employee Name") { ApplicationArea = All; }
                field("Expense Date"; Rec."Expense Date") { ApplicationArea = All; }
                field("Total Amount"; Rec."Total Amount") { ApplicationArea = All; }
                field("Document Status"; Rec."Document Status") { ApplicationArea = All; StyleExpr = StatusStyle; }
                field("Approval Status"; Rec."Approval Status") { ApplicationArea = All; }
                field("Submitted Date"; Rec."Submitted Date") { ApplicationArea = All; }
                field("Approved By"; Rec."Approved By") { ApplicationArea = All; }
                field("GL Posting Date"; Rec."GL Posting Date") { ApplicationArea = All; }
                field("Cost Center"; Rec."Cost Center") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Submit for Approval")
            {
                ApplicationArea = All;
                Caption = 'Submit for Approval';
                Image = SendApprovalRequest;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec."Document Status" = Rec."Document Status"::Draft) and canSubmit;

                trigger OnAction()
                begin
                    if Confirm('Submit expense %1 for approval?', false, Rec."Expense ID") then begin
                        Rec.SubmitForApproval();
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(Approve)
            {
                ApplicationArea = All;
                Caption = 'Approve';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec."Document Status" = Rec."Document Status"::Submitted) and canApprove;

                trigger OnAction()
                begin
                    if Confirm('Approve expense %1?', false, Rec."Expense ID") then begin
                        Rec.ApproveExpense();
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(Reject)
            {
                ApplicationArea = All;
                Caption = 'Reject';
                Image = Reject;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec."Document Status" = Rec."Document Status"::Submitted) and canApprove;

                trigger OnAction()
                begin
                    Rec.TestField("Rejection Reason");
                    if Confirm('Reject expense %1?', false, Rec."Expense ID") then begin
                        Rec.RejectExpense(Rec."Rejection Reason");
                        CurrPage.Update(false);
                    end;
                end;
            }

            action("Post to GL")
            {
                ApplicationArea = All;
                Caption = 'Post to G/L';
                Image = Post;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec."Document Status" = Rec."Document Status"::Approved) and canPost;

                trigger OnAction()
                begin
                    if Confirm('Post expense %1 to G/L?', false, Rec."Expense ID") then begin
                        Rec.PostToGL();
                        Message('Expense %1 has been posted.', Rec."Expense ID");
                        CurrPage.Update(false);
                    end;
                end;
            }

            action("Reverse Posting")
            {
                ApplicationArea = All;
                Caption = 'Reverse Posting';
                Image = ReverseRegister;
                Enabled = (Rec."Document Status" = Rec."Document Status"::Posted) and canPost;

                trigger OnAction()
                var
                    ExpensePosting: Codeunit "Expense Posting";
                begin
                    if Confirm('Reverse posted expense %1?', false, Rec."Expense ID") then begin
                        ExpensePosting.ReverseExpensePosting(Rec);
                        CurrPage.Update(false);
                    end;
                end;
            }

            action("View G/L Entries")
            {
                ApplicationArea = All;
                Caption = 'View G/L Entries';
                Image = GeneralLedger;

                trigger OnAction()
                var
                    GLEntry: Record "G/L Entry";
                begin
                    GLEntry.SetRange("Document No.", Rec."Expense ID");
                    Page.Run(Page::"General Ledger Entries", GLEntry);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStyle();
        SetUserPermissions();

    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetStyle();
        SetUserPermissions();
    end;

    trigger OnOpenPage()
    begin
        SetUserPermissions();
    end;

    local procedure SetStyle()
    begin
        case Rec."Document Status" of
            Rec."Document Status"::Draft:
                StatusStyle := 'Standard';
            Rec."Document Status"::Submitted:
                StatusStyle := 'Attention';
            Rec."Document Status"::Approved,
            Rec."Document Status"::Posted,
            Rec."Document Status"::Paid:
                StatusStyle := 'Favorable';
            Rec."Document Status"::Cancelled:
                StatusStyle := 'Unfavorable';
        end;
    end;

    local procedure SetUserPermissions()
    begin
        canSubmit := rec.CurrentUserCanSubmit();
        canApprove := rec.CurrentUserCanApprove();
        canPost := rec.CurrentUserCanPost();
    end;

    var
        StatusStyle: Text;
        canSubmit: Boolean;
        canApprove: Boolean;
        canPost: Boolean;
}

page 50101 "Expense Card"
{
    ApplicationArea = All;
    Caption = 'Expense Claim';
    PageType = Document;
    SourceTable = "Expense Header";
    UsageCategory = Documents;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Expense ID"; Rec."Expense ID") { ApplicationArea = All; Editable = IsDraft; }
                field("Employee No."; Rec."Employee No.") { ApplicationArea = All; Editable = IsDraft; }
                field("Employee Name"; Rec."Employee Name") { ApplicationArea = All; Editable = false; }
                field("Cost Center"; Rec."Cost Center") { ApplicationArea = All; Editable = false; }
                field("Expense Date"; Rec."Expense Date") { ApplicationArea = All; Editable = IsDraft; }
                field("Currency Code"; Rec."Currency Code") { ApplicationArea = All; Editable = IsDraft; }
                field("Total Amount"; Rec."Total Amount") { ApplicationArea = All; Editable = false; }
            }

            group(Status)
            {
                Caption = 'Status and Approval';
                field("Document Status"; Rec."Document Status") { ApplicationArea = All; Editable = false; }
                field("Approval Status"; Rec."Approval Status") { ApplicationArea = All; Editable = false; }
                field("Submitted Date"; Rec."Submitted Date") { ApplicationArea = All; Editable = false; }
                field("Next Approver"; Rec."Next Approver") { ApplicationArea = All; Editable = false; }
                field("Approved By"; Rec."Approved By") { ApplicationArea = All; Editable = false; }
                field("Approved Date"; Rec."Approved Date") { ApplicationArea = All; Editable = false; }
                field("GL Posting Date"; Rec."GL Posting Date") { ApplicationArea = All; Editable = Rec."Document Status" = Rec."Document Status"::Approved; }
                field("Rejection Reason"; Rec."Rejection Reason") { ApplicationArea = All; Editable = Rec."Document Status" = Rec."Document Status"::Submitted; MultiLine = true; }
            }

            group(Additional)
            {
                Caption = 'Additional';
                field(Notes; Rec.Notes) { ApplicationArea = All; Editable = IsDraft; MultiLine = true; }
                field("Check No."; Rec."Check No.") { ApplicationArea = All; Editable = Rec."Document Status" = Rec."Document Status"::Posted; }
            }

            part(Lines; "Expense Lines SubPage")
            {
                ApplicationArea = All;
                SubPageLink = "Expense ID" = field("Expense ID");
                Editable = IsDraft;
                UpdatePropagation = Both;
            }

            group(Audit)
            {
                Caption = 'Audit';
                field("Created By"; Rec."Created By") { ApplicationArea = All; Editable = false; }
                field("Created DateTime"; Rec."Created DateTime") { ApplicationArea = All; Editable = false; }
                field("Modified By"; Rec."Modified By") { ApplicationArea = All; Editable = false; }
                field("Modified DateTime"; Rec."Modified DateTime") { ApplicationArea = All; Editable = false; }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Submit for Approval")
            {
                ApplicationArea = All;
                Caption = 'Submit for Approval';
                Image = SendApprovalRequest;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec."Document Status" = Rec."Document Status"::Draft) and cansubmit;

                trigger OnAction()
                begin
                    if Confirm('Submit expense %1 for approval?', false, Rec."Expense ID") then begin
                        Rec.SubmitForApproval();
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(Approve)
            {
                ApplicationArea = All;
                Caption = 'Approve';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec."Document Status" = Rec."Document Status"::Submitted) and canApprove;

                trigger OnAction()
                begin
                    if Confirm('Approve expense %1?', false, Rec."Expense ID") then begin
                        Rec.ApproveExpense();
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(Reject)
            {
                ApplicationArea = All;
                Caption = 'Reject';
                Image = Reject;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec."Document Status" = Rec."Document Status"::Submitted) and canApprove;

                trigger OnAction()
                begin
                    Rec.TestField("Rejection Reason");
                    if Confirm('Reject expense %1?', false, Rec."Expense ID") then begin
                        Rec.RejectExpense(Rec."Rejection Reason");
                        CurrPage.Update(false);
                    end;
                end;
            }

            action("Post to GL")
            {
                ApplicationArea = All;
                Caption = 'Post to G/L';
                Image = Post;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec."Document Status" = Rec."Document Status"::Approved) and canPost;

                trigger OnAction()
                begin
                    if Confirm('Post expense %1 to G/L?', false, Rec."Expense ID") then begin
                        Rec.PostToGL();
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsDraft := Rec."Document Status" = Rec."Document Status"::Draft;
        SetUserPermissions();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsDraft := Rec."Document Status" = Rec."Document Status"::Draft;
        SetUserPermissions();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        IsDraft := true;
        SetUserPermissions();
    end;

    trigger OnOpenPage()
    begin
        SetUserPermissions();
    end;

    local procedure SetUserPermissions()
    begin
        canSubmit := rec.CurrentUserCanSubmit();
        canApprove := rec.CurrentUserCanApprove();
        canPost := rec.CurrentUserCanPost();
    end;

    var
        IsDraft: Boolean;
        canSubmit: Boolean;
        canApprove: Boolean;
        canPost: Boolean;
}

page 50102 "Expense Lines SubPage"
{

    Caption = 'Expense Lines';
    PageType = ListPart;
    SourceTable = "Expense Line";
    AutoSplitKey = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Line No."; Rec."Line No.") { ApplicationArea = All; Editable = false; }
                field("Expense Category"; Rec."Expense Category") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Expense Date"; Rec."Expense Date") { ApplicationArea = All; }
                field("Expense Amount"; Rec."Expense Amount") { ApplicationArea = All; }
                field("Is Taxable"; Rec."Is Taxable") { ApplicationArea = All; }
                field("Tax Rate"; Rec."Tax Rate") { ApplicationArea = All; }
                field("Tax Amount"; Rec."Tax Amount") { ApplicationArea = All; Editable = false; }
                field("Net Amount"; Rec."Net Amount") { ApplicationArea = All; Editable = false; }
                field("Approved Line Amount"; Rec."Approved Line Amount") { ApplicationArea = All; }
                field("GL Account"; Rec."GL Account") { ApplicationArea = All; }
                field(Justification; Rec.Justification) { ApplicationArea = All; }
                field("Receipt Required"; Rec."Receipt Required") { ApplicationArea = All; Editable = false; }
            }
        }
    }
}

page 50103 "Expense Categories"
{
    ApplicationArea = All;
    Caption = 'Expense Categories';
    PageType = List;
    SourceTable = "Expense Category";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Category Code"; Rec."Category Code") { ApplicationArea = All; }
                field("Category Name"; Rec."Category Name") { ApplicationArea = All; }
                field("GL Account No."; Rec."GL Account No.") { ApplicationArea = All; }
                field("Is Taxable"; Rec."Is Taxable") { ApplicationArea = All; }
                field("Default Tax Rate"; Rec."Default Tax Rate") { ApplicationArea = All; }
                field("Max Amount Per Claim"; Rec."Max Amount Per Claim") { ApplicationArea = All; }
                field("Is Active"; Rec."Is Active") { ApplicationArea = All; }
            }
        }
    }
}

page 50104 "Employee Expense Setup"
{
    ApplicationArea = All;
    Caption = 'Employee Expense Setup';
    PageType = Card;
    SourceTable = "Employee Expense Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Setup ID"; Rec."Setup ID") { ApplicationArea = All; }
                field("Approval Required Above"; Rec."Approval Required Above") { ApplicationArea = All; }
                field("Manager Approval Limit"; Rec."Manager Approval Limit") { ApplicationArea = All; }
                field("Director Approval Limit"; Rec."Director Approval Limit") { ApplicationArea = All; }
                field("CFO Approval Required"; Rec."CFO Approval Required") { ApplicationArea = All; }
                field("Require Receipts Above"; Rec."Require Receipts Above") { ApplicationArea = All; }
                field("Days To Submit After Expense"; Rec."Days To Submit After Expense") { ApplicationArea = All; }
                field("Reimbursement Method"; Rec."Reimbursement Method") { ApplicationArea = All; }
                field("GL Account Reimbursement"; Rec."GL Account Reimbursement") { ApplicationArea = All; }
                field("Default Payment Terms"; Rec."Default Payment Terms") { ApplicationArea = All; }
            }
        }
    }
}

page 50105 "Employee Approval Hierarchy"
{
    ApplicationArea = All;
    Caption = 'Employee Approval Hierarchy';
    PageType = List;
    SourceTable = "Employee Approval Hierarchy";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Employee No."; Rec."Employee No.") { ApplicationArea = All; }
                field("Approval Sequence"; Rec."Approval Sequence") { ApplicationArea = All; }
                field("Approving Employee No."; Rec."Approving Employee No.") { ApplicationArea = All; }
                field("Approval Type"; Rec."Approval Type") { ApplicationArea = All; }
                field("Delegate To Employee No."; Rec."Delegate To Employee No.") { ApplicationArea = All; }
                field("Delegation Start Date"; Rec."Delegation Start Date") { ApplicationArea = All; }
                field("Delegation End Date"; Rec."Delegation End Date") { ApplicationArea = All; }
                field("Is Active"; Rec."Is Active") { ApplicationArea = All; }
            }
        }
    }
}

page 50106 "Expense Logs"
{
    ApplicationArea = All;
    Caption = 'Expense Logs';
    PageType = List;
    SourceTable = "Expense Log";
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Expense ID"; Rec."Expense ID") { ApplicationArea = All; }
                field("Action Type"; Rec."Action Type") { ApplicationArea = All; }
                field("User ID"; Rec."User ID") { ApplicationArea = All; }
                field("Action DateTime"; Rec."Action DateTime") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Employee No."; Rec."Employee No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}

page 50107 "Posting Error Logs"
{
    ApplicationArea = All;
    Caption = 'Posting Error Logs';
    PageType = List;
    SourceTable = "Posting Error Log";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; Editable = false; }
                field("Document Type"; Rec."Document Type") { ApplicationArea = All; }
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field("Error Message"; Rec."Error Message") { ApplicationArea = All; }
                field("Error DateTime"; Rec."Error DateTime") { ApplicationArea = All; Editable = false; }
                field("User ID"; Rec."User ID") { ApplicationArea = All; Editable = false; }
                field(Resolved; Rec.Resolved) { ApplicationArea = All; }
                field("Resolution Notes"; Rec."Resolution Notes") { ApplicationArea = All; }
            }
        }
    }
}
