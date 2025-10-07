# Blueprint Library

Curated blueprints that serve as exemplars for different verticals and guardrail presets. Each file is referenced by `BlueprintLibraryService` and can seed prompts or be executed directly.

| File | Tags | Description |
|------|------|-------------|
| `account_create.json` | `Account`, `Create`, `Sales` | Create a new account with name, type, and industry. |
| `case_create.json` | `Case`, `Create`, `Service` | Create a new case with subject, description, and priority. |
| `case_create_followup_task.json` | `Case`, `Task`, `Create`, `Followup`, `NextStep` | Create a follow-up task tied to a case. |
| `case_escalate.json` | `Case`, `Escalation`, `Service` | Escalate case with new priority and owner. |
| `case_escalate_tier2.json` | `Case`, `Escalate`, `Ownership`, `Priority`, `Queue` | Reassign to Tier 2 and set priority/status. |
| `campaign_create.json` | `Campaign`, `Create`, `Marketing` | Create a new campaign with name, type, and dates. |
| `campaign_member_add.json` | `CampaignMember`, `Create`, `Marketing` | Add contact/lead to a campaign with status. |
| `contact_create.json` | `Contact`, `Create`, `Sales` | Create a new contact with name, email, and phone. |
| `contract_create.json` | `Contract`, `Create`, `Sales` | Create a new contract with account and term. |
| `event_create.json` | `Event`, `Create`, `Activity` | Create a new event with subject and scheduling. |
| `lead_create.json` | `Lead`, `Create`, `Sales` | Create a new lead with name, company, and contact info. |
| `lead_mark_qualified.json` | `Lead`, `Qualification`, `Status`, `Rating` | Move lead to qualified state with rating. |
| `lead_qualify.json` | `Lead`, `Qualification`, `Sales` | Qualify lead and update status/rating. |
| `opportunity_close_lost.json` | `Opportunity`, `Stage`, `ClosedLost`, `Reason` | Mark opportunity as Closed Lost with reason. |
| `opportunity_closed_won.json` | `Opportunity`, `Update`, `Stage`, `ClosedWon` | Set opportunity to Closed Won (legacy format). |
| `opportunity_create.json` | `Opportunity`, `Create`, `Sales` | Create a new opportunity with account and stage. |
| `oppty_closed_won.json` | `Opportunity`, `Stage`, `ClosedWon`, `Sales` | Set opportunity to Closed Won with CloseDate. |
| `order_create.json` | `Order`, `Create`, `Sales` | Create a new order with account and effective date. |
| `pricebook_entry_create.json` | `PricebookEntry`, `Create`, `CPQ` | Create pricebook entry with product and unit price. |
| `product_create.json` | `Product2`, `Create`, `CPQ` | Create a new product with name and description. |
| `quote_create.json` | `Quote`, `Create`, `CPQ` | Create a new quote with opportunity and expiration. |
| `quote_line_create.json` | `QuoteLineItem`, `Create`, `CPQ` | Create quote line item with product and pricing. |
| `quote_line_discount_set.json` | `QuoteLineItem`, `Update`, `CPQ`, `Discount` | Set discount percentage on quote line item. |
| `task_create.json` | `Task`, `Create`, `Activity` | Create a new task with subject and due date. |

Run `node scripts/build-blueprint-library.js` (or `npm run blueprints:build`) after editing these JSON files to refresh the `BlueprintLibrary` static resource.
