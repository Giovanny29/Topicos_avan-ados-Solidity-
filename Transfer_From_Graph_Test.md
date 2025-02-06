````mermaid
graph TD
    A[Start] --> B{msg.sender == from?}
    B -->|Yes| D{Valid to address?}
    B -->|No| C{isApprovedForAll?}
    C -->|Yes| D
    C -->|No| E[Revert: Not approved]
    D -->|Yes| F{Sufficient balance?}
    D -->|No| G[Revert: Zero address]
    F -->|Yes| H[Transfer tokens]
    F -->|No| I[Revert: Insufficient balance]
    H --> J[End]