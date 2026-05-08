# Business Central Employee Expense Management System

A custom Microsoft Dynamics 365 Business Central extension built in AL for managing employee expense claims, approval workflow, role-based action control, reimbursement setup, and G/L posting.

## Overview

This project allows users to create employee expense claims, add expense lines, submit claims for approval, approve or reject claims, and post approved expenses to the General Ledger.

It was developed as a learning project to understand Business Central custom tables, pages, validations, approval workflow, role-based controls, and posting logic.

## Features

- Expense claim header and line management
- Expense categories such as Travel, Meals, and Hotel
- Employee-based expense submission
- Automatic total amount calculation
- Approval workflow with configurable limits
- Role-based controls for Submit, Approve, Reject, and Post to G/L
- Auto-approval for expenses below threshold
- G/L posting using Gen. Journal Line
- Employee Expense Payable setup
- Expense logs and posting error logs
- Custom employee ledger tracking

## Workflow

Draft → Submitted → Approved → Posted → Paid / Cancelled

## Role-Based Control

The system uses a custom **Expense User Setup** page to control user permissions.

Roles can be configured using:

- Can Submit
- Can Approve
- Can Post to G/L
- Is Active

This ensures that users can only perform actions they are allowed to perform. For example, an employee may submit claims, a manager may approve claims, and a finance user may post approved claims to the General Ledger.

## Posting Logic

When an approved expense is posted, the system creates balanced G/L entries:

Debit: Expense Account  
Credit: Employee Expense Payable Account

Example:

Debit: Travel Expense = 10,000  
Credit: Employee Expense Payable = 10,000

## Main Objects

| Object ID | Object Name |
|---|---|
| 50100 | Expense Header |
| 50101 | Expense Line |
| 50102 | Expense Category |
| 50103 | Employee Expense Setup |
| 50104 | Employee Approval Hierarchy |
| 50105 | Expense Log |
| 50106 | Posting Error Log |
| 50107 | Employee Entry Ledger Ext |
| 50108 | Expense User Setup |
| 50101 | Expense Posting Codeunit |

## Setup Required

Before testing, the following setup is required:

- Employee Expense Setup
- Expense Categories
- Employee Expense Payable G/L Account
- Employee Approval Hierarchy
- Expense User Setup

Example setup:

Setup ID: DEFAULT  
Approval Required Above: 5000  
Manager Approval Limit: 20000  
Director Approval Limit: 100000  
Require Receipts Above: 3000  
Days To Submit After Expense: 90  
G/L Account Reimbursement: 22800

## Test Scenario

Example tested claim:

Employee: MH - Marty Horst  
Expense Category: TRAVEL  
Expense Amount: 10,000  
Expense Date: 1/25/2024  
Document Status: Posted  
Approval Status: Approved

## Screenshots

### Employee Expense Setup

![Expense-Setup.png](screenshots/expense-setup.png)

### Expense Categories

![Expense Categories](screenshots/expense-categories.png)

### Expense User Setup

![Expense User Setup](screenshots/expense-user-setup.png)

### Expense Claim Approved

![Expense Claim Approved](screenshots/expense-claim-approved.png)

### Expense Claim Posted

![Expense Claim Posted](screenshots/expense-claim-posted.png)

## Technologies Used

- Microsoft Dynamics 365 Business Central
- AL Language
- Visual Studio Code
- Business Central On-Prem / Local Sandbox
- General Journal Posting
- G/L Account Integration
- Employee Master Integration

## Learning Outcomes

Through this project, I learned:

- Custom table and page design in Business Central
- Master-detail relationship using header and line tables
- Field validations and table triggers
- Approval workflow handling
- Role-based action control using custom setup
- Posting to G/L using Gen. Journal Line
- Using balancing accounts instead of direct G/L Entry insertion
- Creating audit logs and error logs
- Integrating custom modules with standard Business Central records

## Future Improvements

- Add receipt attachments
- Add email notifications
- Add payment processing
- Add Power BI reporting
- Add standard Business Central permission sets
- Add G/L entry drill-down from the expense card

## Author

Laiba Laghari  
Computer Science Student  
Business Central / AL Development Learner  
LinkedIn: www.linkedin.com/in/laibalaghari-d365
