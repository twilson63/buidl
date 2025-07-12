# Slack Bot Server Project Plan

## Project Overview

A Lua-based Slack bot server that interfaces with a specific Slack channel, stores message history, and provides AI-powered responses through OpenRouter integration. Built using the Hype framework for zero-dependency deployment.

## Architecture

### Core Components

1. **Slack Integration Layer**
   - Real-time message monitoring via Socket Mode
   - Message storage for history tracking
   - Bot mention detection and response handling

2. **Message Storage System**
   - Persistent storage using Hype's embedded key-value database
   - Message indexing for efficient retrieval
   - Custom vector database layer for semantic search

3. **AI Processing Pipeline**
   - Context extraction from message history
   - Token preparation for LLM queries
   - OpenRouter API integration for AI responses

4. **Action Execution Engine**
   - AI response analysis and action determination
   - Command execution capabilities
   - Result reporting back to Slack

5. **Vector Database Layer**
   - Semantic search over message history
   - Embedding generation for context retrieval
   - Similarity matching for relevant context

## Technical Stack

- **Runtime**: Hype framework (Lua-based)
- **Database**: Hype embedded key-value store (BoltDB)
- **HTTP Server**: Hype HTTP server module
- **Slack API**: Socket Mode for real-time events
- **AI Service**: OpenRouter API for LLM access

## Project Structure

```
slack-bot-server/
├── main.lua                 # Application entry point
├── src/
│   ├── slack/
│   │   ├── client.lua       # Slack Socket Mode client
│   │   ├── events.lua       # Event handling logic
│   │   └── auth.lua         # Authentication management
│   ├── storage/
│   │   ├── database.lua     # Key-value store operations
│   │   ├── messages.lua     # Message storage/retrieval
│   │   └── vectors.lua      # Vector database implementation
│   ├── ai/
│   │   ├── openrouter.lua   # OpenRouter API client
│   │   ├── context.lua      # Context building from history
│   │   └── embeddings.lua   # Text embedding generation
│   ├── actions/
│   │   ├── parser.lua       # AI response parsing
│   │   ├── executor.lua     # Action execution engine
│   │   └── commands.lua     # Available command implementations
│   └── utils/
│       ├── http.lua         # HTTP utility functions
│       ├── json.lua         # JSON handling
│       └── logger.lua       # Logging utilities
├── config/
│   └── settings.lua         # Configuration management
└── tests/
    └── ...                  # Test files
```

## Implementation Phases

### Phase 1: Foundation Setup (Week 1-2)
- Set up Hype development environment
- Implement basic HTTP server with health checks
- Create database schema and basic CRUD operations
- Set up configuration management system

### Phase 2: Slack Integration (Week 3-4)
- Implement Slack Socket Mode client
- Set up OAuth token management
- Create event handling for message events
- Implement message storage in key-value store

### Phase 3: Vector Database Layer (Week 5-6)
- Design vector storage schema on top of key-value store
- Implement text embedding generation
- Create similarity search functionality
- Build context retrieval system

### Phase 4: AI Integration (Week 7-8)
- Implement OpenRouter API client
- Create context building from message history
- Implement mention detection and response logic
- Set up token management and rate limiting

### Phase 5: Action System (Week 9-10)
- Build AI response parsing system
- Implement action execution engine
- Create basic command set (help, status, etc.)
- Add error handling and logging

### Phase 6: Testing & Optimization (Week 11-12)
- Comprehensive testing of all components
- Performance optimization
- Security review and hardening
- Documentation completion

## Key Features

### Core Functionality
- **Message Monitoring**: Real-time tracking of all channel messages
- **History Storage**: Persistent storage of message history with metadata
- **Mention Detection**: Automatic detection of bot mentions (@botname)
- **Context Building**: Intelligent context extraction from message history
- **AI Response**: Integration with OpenRouter for LLM-powered responses
- **Action Execution**: Ability to execute commands based on AI feedback

### Advanced Features
- **Semantic Search**: Vector-based similarity search over message history
- **Context Optimization**: Token-efficient context building for LLM queries
- **Rate Limiting**: Proper handling of Slack and OpenRouter API limits
- **Error Recovery**: Robust error handling and automatic retry mechanisms
- **Logging**: Comprehensive logging for debugging and monitoring

## Configuration Requirements

### Environment Variables
```lua
-- Slack Configuration
SLACK_BOT_TOKEN = "xoxb-your-bot-token"
SLACK_APP_TOKEN = "xapp-your-app-token"
SLACK_CHANNEL_ID = "C1234567890"

-- OpenRouter Configuration
OPENROUTER_API_KEY = "your-openrouter-key"
OPENROUTER_MODEL = "anthropic/claude-3.5-sonnet"

-- Server Configuration
PORT = 8080
DATABASE_PATH = "./data/bot.db"
LOG_LEVEL = "info"
```

### Slack App Configuration
- Socket Mode enabled
- Event subscriptions: `message.channels`, `app_mention`
- OAuth scopes: `channels:read`, `channels:history`, `chat:write`

## Vector Database Design

### Schema Design
```lua
-- Message vectors stored as:
-- Key: "vector:message:{message_id}"
-- Value: {
--   embedding = {0.1, 0.2, ...},  -- 1536-dimensional vector
--   text = "original message text",
--   timestamp = 1234567890,
--   user_id = "U1234567890",
--   metadata = {...}
-- }

-- Index for similarity search:
-- Key: "index:vectors"
-- Value: {
--   {id = "msg1", vector = {...}},
--   {id = "msg2", vector = {...}},
--   ...
-- }
```

### Similarity Search Algorithm
- Use cosine similarity for vector comparison
- Implement approximate nearest neighbor search
- Support for metadata filtering (time range, user, etc.)

## API Design

### Internal API Structure
```lua
-- Slack Events
handle_message_event(event)
handle_app_mention(event)

-- Storage Operations
store_message(message)
search_similar_messages(query, limit)
get_message_history(channel, limit)

-- AI Operations
generate_embedding(text)
build_context(query, history)
query_openrouter(context, query)

-- Action System
parse_ai_response(response)
execute_action(action)
report_result(result)
```

## Deployment Strategy

### Cloud Deployment
- Single binary deployment using Hype compilation
- Cloud server with git access and package management
- Environment-based configuration
- Automatic restart on failure

### Requirements
- Linux server with curl/wget for installation
- Git for source code management
- Network access to Slack and OpenRouter APIs
- Persistent storage for database files

### Security Considerations
- Secure token storage and rotation
- Rate limiting and abuse prevention
- Input validation and sanitization
- Audit logging for security events

## Testing Strategy

### Unit Tests
- Individual component testing
- Mock external API calls
- Database operation validation

### Integration Tests
- End-to-end message flow testing
- Slack API integration testing
- OpenRouter API integration testing

### Performance Tests
- Vector search performance benchmarks
- Database operation speed tests
- Memory usage optimization

## Monitoring & Maintenance

### Logging
- Structured logging with different levels
- Request/response logging for APIs
- Performance metrics tracking

### Health Checks
- Database connectivity checks
- External API availability checks
- Memory and CPU usage monitoring

### Backup Strategy
- Regular database backups
- Configuration backup
- Recovery procedures documentation

## Success Metrics

- **Functionality**: All core features working reliably
- **Performance**: Sub-second response times for queries
- **Reliability**: 99.9% uptime target
- **Scalability**: Handle 1000+ messages per day
- **Security**: No security incidents or data breaches

## Risk Assessment

### Technical Risks
- Hype framework limitations or bugs
- Slack API rate limiting issues
- OpenRouter API availability/costs
- Vector search performance at scale

### Mitigation Strategies
- Comprehensive testing before deployment
- Implement proper error handling and retries
- Monitor API usage and costs
- Performance optimization and caching

## Timeline Summary

- **Total Duration**: 12 weeks
- **MVP Ready**: Week 8
- **Production Ready**: Week 12
- **Key Milestones**: 
  - Week 4: Basic Slack integration
  - Week 6: Vector database operational
  - Week 8: AI integration complete
  - Week 12: Full deployment ready

This project plan provides a comprehensive roadmap for building a sophisticated Slack bot server using Lua and the Hype framework, with advanced AI capabilities and robust message processing.