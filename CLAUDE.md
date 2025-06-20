# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Open WebUI is a feature-rich, extensible, self-hosted AI platform that operates entirely offline. It provides a web interface for various LLM runners like Ollama and OpenAI-compatible APIs, with built-in RAG capabilities, code execution, and extensive customization options.

## Architecture

### Dual-Stack Application
- **Backend**: Python FastAPI application (`backend/open_webui/`)
- **Frontend**: SvelteKit application (`src/`)
- **Communication**: REST API endpoints and WebSocket connections

### Key Backend Components
- `backend/open_webui/main.py` - FastAPI application entry point with all route definitions
- `backend/open_webui/routers/` - API route handlers organized by functionality
- `backend/open_webui/models/` - Database models using SQLAlchemy/Peewee
- `backend/open_webui/utils/` - Utility functions for auth, middleware, embeddings, etc.
- `backend/open_webui/config.py` - Configuration management
- `backend/open_webui/internal/db.py` - Database connection and session management

### Key Frontend Components
- `src/routes/` - SvelteKit routes and pages
- `src/lib/components/` - Reusable Svelte components organized by feature area
- `src/lib/apis/` - Frontend API client functions
- `src/lib/stores/` - Svelte stores for state management
- `src/lib/utils/` - Frontend utility functions

## Development Commands

### Frontend Development
```bash
# Install dependencies
npm install

# Start development server (includes Pyodide setup)
npm run dev

# Start on specific port
npm run dev:5050

# Build for production
npm run build

# Build with watch mode
npm run build:watch

# Preview production build
npm run preview
```

### Code Quality & Testing
```bash
# Run all linting (frontend, types, backend)
npm run lint

# Lint frontend code
npm run lint:frontend

# Check TypeScript types
npm run lint:types

# Lint backend Python code
npm run lint:backend

# Format frontend code
npm run format

# Format backend Python code
npm run format:backend

# Run frontend tests
npm run test:frontend

# Run Cypress E2E tests
npm run cy:open
```

### Backend Development
```bash
# Navigate to backend directory
cd backend

# Install Python dependencies
pip install -r requirements.txt

# Start backend development server
./dev.sh
# or
uvicorn open_webui.main:app --port 8080 --host 0.0.0.0 --forwarded-allow-ips '*' --reload
```

### Docker Development
```bash
# Using Makefile commands
make install          # Start with docker-compose
make start           # Start existing containers
make startAndBuild   # Build and start
make stop            # Stop containers
make update          # Pull, rebuild, and restart
```

### Internationalization
```bash
# Parse and update translation files
npm run i18n:parse
```

## Project Structure

### Backend (`backend/open_webui/`)
- **Routers**: API endpoints organized by domain (chats, users, models, etc.)
- **Models**: Database entities and business logic
- **Utils**: Cross-cutting utilities (auth, middleware, embeddings, RAG, etc.)
- **Internal**: Database and core infrastructure
- **Socket**: WebSocket handling for real-time features
- **Tasks**: Background task processing
- **Storage**: File storage providers

### Frontend (`src/`)
- **Routes**: Page-level components following SvelteKit file-based routing
- **Components**: Organized by feature area (chat, admin, workspace, etc.)
- **APIs**: Client-side API communication modules
- **Stores**: Application state management
- **Utils**: Frontend utilities and helpers

### Key Directories to Understand
- `src/routes/(app)/` - Main application pages
- `src/lib/components/chat/` - Chat interface components
- `src/lib/components/admin/` - Admin panel functionality
- `src/lib/components/workspace/` - Knowledge, models, prompts, tools management
- `backend/open_webui/routers/` - All API endpoint implementations

## Configuration

### Environment Variables
- Backend configuration is managed through `backend/open_webui/config.py`
- Frontend build configuration in `vite.config.ts` and `svelte.config.js`
- Environment-specific settings in `backend/open_webui/env.py`

### Key Configuration Areas
- **Database**: Supports SQLite, PostgreSQL, MySQL
- **LLM Integration**: Ollama, OpenAI, and custom API endpoints
- **RAG**: Vector databases (ChromaDB, Qdrant, etc.), embedding models
- **Authentication**: OAuth, LDAP, API keys
- **File Storage**: Local, S3, Azure Blob, Google Cloud Storage
- **Code Execution**: Jupyter integration for Python code execution

## Key Features to Understand

### RAG (Retrieval Augmented Generation)
- Document processing and embedding generation
- Vector database integration
- Web search capabilities
- Knowledge base management

### Multi-Model Support
- Simultaneous conversation with multiple models
- Model access control and permissions
- Pipeline processing for filtering and enhancement

### Tool Integration
- Custom Python function execution
- External tool server connections
- Code interpreter capabilities

### Real-time Features
- WebSocket connections for live chat
- Streaming responses
- Background task processing

## Testing

### E2E Testing
- Cypress tests in `cypress/e2e/`
- Test configurations in `cypress.config.ts`

### Frontend Testing
- Vitest for unit tests
- Test command: `npm run test:frontend`

## Build Process

### Frontend Build
- SvelteKit with static adapter for SPA
- Vite bundler with TypeScript support
- Pyodide integration for Python code execution in browser
- Static asset copying and optimization

### Backend Package
- Hatchling build system
- Python package distribution via PyPI
- Static frontend files included in package

## Development Tips

### Working with the API
- All API routes are defined in `backend/open_webui/main.py`
- Route implementations in `backend/open_webui/routers/`
- Authentication handled via JWT tokens
- CORS configured for development

### Frontend Development
- Hot reload enabled for rapid development
- TypeScript strict mode enabled
- Tailwind CSS for styling
- Component-based architecture with clear separation

### Database Management
- Alembic for database migrations
- Models defined using both SQLAlchemy and Peewee
- Database session management in middleware

## Security Considerations
- User authentication and authorization
- API key management
- File upload restrictions
- SQL injection prevention
- XSS protection