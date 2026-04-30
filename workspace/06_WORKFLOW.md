# Workflow — End-to-End Process Flow

## Workflow Steps

1. **data-writer** → data-writer
2. **normalize_request** → ticket-intake-normalizer
3. **review_prompt** → native-tool: message (depends on normalize_request)
4. **publish_linear** → linear-ticket-publisher (depends on review_prompt)

## Diagram

```
data-writer → normalize_request → review_prompt → publish_linear
```
