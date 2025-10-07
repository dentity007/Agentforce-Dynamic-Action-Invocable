[
  {
    "name": "case_create_followup_task",
    "label": "Case Create Follow-up Task",
    "tags": [
      "Case",
      "Task",
      "Create",
      "Followup",
      "NextStep"
    ],
    "targetSObject": "Task",
    "operation": "CREATE",
    "summary": "Create a follow-up task tied to a case.",
    "checkpoint": "Create a follow-up task tied to a case with optional priority/status/due date.",
    "inputs": [
      {
        "apiName": "WhatId",
        "fieldApiName": "WhatId",
        "label": "Related Case Id",
        "dataType": "Id",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Subject",
        "fieldApiName": "Subject",
        "label": "Subject",
        "dataType": "String",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Priority",
        "fieldApiName": "Priority",
        "label": "Priority",
        "dataType": "String",
        "required": false,
        "usage": "FIELD"
      },
      {
        "apiName": "Status",
        "fieldApiName": "Status",
        "label": "Status",
        "dataType": "String",
        "required": false,
        "usage": "FIELD"
      },
      {
        "apiName": "ActivityDate",
        "fieldApiName": "ActivityDate",
        "label": "Due Date",
        "dataType": "Date",
        "required": false,
        "usage": "FIELD"
      }
    ],
    "guardrails": [
      {
        "type": "FLS_EDIT",
        "params": {
          "fields": [
            "WhatId",
            "Subject",
            "Priority",
            "Status",
            "ActivityDate"
          ]
        }
      },
      {
        "type": "ENUM_ALLOWED",
        "params": {
          "field": "Priority",
          "values": [
            "High",
            "Normal",
            "Low"
          ]
        }
      },
      {
        "type": "ENUM_ALLOWED",
        "params": {
          "field": "Status",
          "values": [
            "Not Started",
            "In Progress",
            "Completed"
          ]
        }
      },
      {
        "type": "SHARING_REQUIRED"
      }
    ]
  },
  {
    "name": "case_escalate",
    "label": "Case Escalation",
    "tags": [
      "service",
      "Case",
      "Escalation"
    ],
    "targetSObject": "Case",
    "operation": "UPDATE",
    "summary": "Escalated case with new priority and owner.",
    "checkpoint": "Escalate the case, adjust priority, and (optionally) reassign ownership.",
    "keyFields": [
      "Id"
    ],
    "inputs": [
      {
        "apiName": "Id",
        "fieldApiName": "Id",
        "label": "Case Id",
        "dataType": "Id",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Status",
        "fieldApiName": "Status",
        "label": "Status",
        "dataType": "String",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Priority",
        "fieldApiName": "Priority",
        "label": "Priority",
        "dataType": "String",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Escalation_Notes__c",
        "fieldApiName": "Escalation_Notes__c",
        "label": "Escalation Notes",
        "dataType": "String",
        "required": false,
        "usage": "FIELD"
      },
      {
        "apiName": "OwnerId",
        "fieldApiName": "OwnerId",
        "label": "New Owner",
        "dataType": "Id",
        "required": false,
        "usage": "FIELD"
      }
    ],
    "guardrails": [
      {
        "type": "FLS_EDIT",
        "params": {
          "fields": [
            "Status",
            "Priority",
            "Escalation_Notes__c",
            "OwnerId"
          ]
        }
      },
      {
        "type": "PII_REDACT",
        "params": {
          "fields": [
            "Escalation_Notes__c"
          ]
        },
        "message": "Redact sensitive escalation notes before execution."
      },
      {
        "type": "SHARING_REQUIRED"
      }
    ]
  },
  {
    "name": "case_escalate_tier2",
    "label": "Case Escalate to Tier 2",
    "tags": [
      "Case",
      "Escalate",
      "Ownership",
      "Priority",
      "Queue"
    ],
    "targetSObject": "Case",
    "operation": "UPDATE",
    "summary": "Escalate a case to Tier 2 with optional priority/status.",
    "checkpoint": "Escalate a case by reassigning to a Tier 2 queue/owner and optionally bumping priority/status.",
    "keyFields": [
      "Id"
    ],
    "inputs": [
      {
        "apiName": "Id",
        "fieldApiName": "Id",
        "label": "Case Id",
        "dataType": "Id",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "OwnerId",
        "fieldApiName": "OwnerId",
        "label": "New Owner/Queue",
        "dataType": "Id",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Priority",
        "fieldApiName": "Priority",
        "label": "Priority",
        "dataType": "String",
        "required": false,
        "usage": "FIELD"
      },
      {
        "apiName": "Status",
        "fieldApiName": "Status",
        "label": "Status",
        "dataType": "String",
        "required": false,
        "usage": "FIELD"
      }
    ],
    "guardrails": [
      {
        "type": "FLS_EDIT",
        "params": {
          "fields": [
            "OwnerId",
            "Priority",
            "Status"
          ]
        }
      },
      {
        "type": "ENUM_ALLOWED",
        "params": {
          "field": "Priority",
          "values": [
            "High",
            "Medium",
            "Low"
          ]
        }
      },
      {
        "type": "SHARING_REQUIRED"
      }
    ]
  },
  {
    "name": "lead_mark_qualified",
    "label": "Lead Mark Qualified",
    "tags": [
      "Lead",
      "Qualification",
      "Status",
      "Rating"
    ],
    "targetSObject": "Lead",
    "operation": "UPDATE",
    "summary": "Move a lead to a qualified state and optionally set rating.",
    "checkpoint": "Move a lead to a qualified state and optionally set a confidence rating.",
    "keyFields": [
      "Id"
    ],
    "inputs": [
      {
        "apiName": "Id",
        "fieldApiName": "Id",
        "label": "Lead Id",
        "dataType": "Id",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Status",
        "fieldApiName": "Status",
        "label": "Status",
        "dataType": "String",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Rating",
        "fieldApiName": "Rating",
        "label": "Rating",
        "dataType": "String",
        "required": false,
        "usage": "FIELD"
      }
    ],
    "guardrails": [
      {
        "type": "FLS_EDIT",
        "params": {
          "fields": [
            "Status",
            "Rating"
          ]
        }
      },
      {
        "type": "ENUM_ALLOWED",
        "params": {
          "field": "Status",
          "values": [
            "Qualified",
            "Working - Qualified"
          ]
        }
      },
      {
        "type": "ENUM_ALLOWED",
        "params": {
          "field": "Rating",
          "values": [
            "Hot",
            "Warm",
            "Cold"
          ]
        }
      },
      {
        "type": "SHARING_REQUIRED"
      }
    ]
  },
  {
    "name": "lead_qualify",
    "label": "Lead Qualification",
    "tags": [
      "sales",
      "Lead",
      "Qualification"
    ],
    "targetSObject": "Lead",
    "operation": "UPDATE",
    "summary": "Qualified lead and updated status/rating.",
    "checkpoint": "Qualify the lead and update status.",
    "keyFields": [
      "Id"
    ],
    "inputs": [
      {
        "apiName": "Id",
        "fieldApiName": "Id",
        "label": "Lead Id",
        "dataType": "Id",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Status",
        "fieldApiName": "Status",
        "label": "Status",
        "dataType": "String",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Rating",
        "fieldApiName": "Rating",
        "label": "Rating",
        "dataType": "String",
        "required": false,
        "usage": "FIELD"
      },
      {
        "apiName": "IsConverted",
        "fieldApiName": "IsConverted",
        "label": "Is Converted",
        "dataType": "Boolean",
        "required": false,
        "usage": "FIELD"
      }
    ],
    "guardrails": [
      {
        "type": "FLS_EDIT",
        "params": {
          "fields": [
            "Status",
            "Rating",
            "IsConverted"
          ]
        }
      },
      {
        "type": "SHARING_REQUIRED"
      }
    ]
  },
  {
    "name": "opportunity_close_lost",
    "label": "Opportunity Close Lost",
    "tags": [
      "Opportunity",
      "Stage",
      "ClosedLost",
      "Reason"
    ],
    "targetSObject": "Opportunity",
    "operation": "UPDATE",
    "summary": "Mark an opportunity as Closed Lost and optionally add a reason.",
    "checkpoint": "Mark an opportunity as Closed Lost and optionally log a brief reason in Description.",
    "keyFields": [
      "Id"
    ],
    "inputs": [
      {
        "apiName": "Id",
        "fieldApiName": "Id",
        "label": "Opportunity Id",
        "dataType": "Id",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "StageName",
        "fieldApiName": "StageName",
        "label": "Stage",
        "dataType": "String",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "Description",
        "fieldApiName": "Description",
        "label": "Loss Reason",
        "dataType": "String",
        "required": false,
        "usage": "FIELD"
      }
    ],
    "guardrails": [
      {
        "type": "FLS_EDIT",
        "params": {
          "fields": [
            "StageName",
            "Description"
          ]
        }
      },
      {
        "type": "ENUM_ALLOWED",
        "params": {
          "field": "StageName",
          "values": [
            "Closed Lost"
          ]
        }
      },
      {
        "type": "SHARING_REQUIRED"
      }
    ]
  },
  {
    "name": "opportunity_closed_won",
    "tags": [
      "Opportunity",
      "Update",
      "Stage",
      "ClosedWon"
    ],
    "operation": "UPDATE",
    "targetSObject": "Opportunity",
    "inputs": {
      "Id": {
        "type": "Id",
        "required": true
      },
      "StageName": {
        "type": "Picklist",
        "required": true,
        "enum": [
          "Closed Won"
        ]
      },
      "CloseDate": {
        "type": "Date",
        "required": false
      }
    },
    "guardrails": {
      "fls": {
        "fields": [
          "StageName",
          "CloseDate"
        ],
        "requireUpdateable": true
      },
      "sharing": "WITH_SHARING"
    },
    "checkpoint": "Set opportunity to Closed Won with optional CloseDate."
  },
  {
    "name": "oppty_closed_won",
    "label": "Opportunity Closed Won",
    "tags": [
      "sales",
      "Opportunity",
      "Stage",
      "ClosedWon"
    ],
    "targetSObject": "Opportunity",
    "operation": "UPDATE",
    "summary": "Updated Opportunity stage to Closed Won.",
    "checkpoint": "Set opportunity to Closed Won with optional CloseDate.",
    "keyFields": [
      "Id"
    ],
    "inputs": [
      {
        "apiName": "Id",
        "fieldApiName": "Id",
        "label": "Opportunity Id",
        "dataType": "Id",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "StageName",
        "fieldApiName": "StageName",
        "label": "New Stage",
        "dataType": "String",
        "required": true,
        "usage": "FIELD"
      },
      {
        "apiName": "CloseDate",
        "fieldApiName": "CloseDate",
        "label": "Close Date",
        "dataType": "Date",
        "required": false,
        "usage": "FIELD"
      }
    ],
    "guardrails": [
      {
        "type": "FLS_EDIT",
        "params": {
          "fields": [
            "StageName",
            "CloseDate"
          ]
        }
      },
      {
        "type": "ENUM_ALLOWED",
        "params": {
          "field": "StageName",
          "values": [
            "Closed Won"
          ]
        }
      },
      {
        "type": "SHARING_REQUIRED"
      }
    ]
  }
]