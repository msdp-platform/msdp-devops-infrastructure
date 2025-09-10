# 📊 Database Design Diagrams

This directory contains enhanced Mermaid diagram files for the Multi-Service Delivery Platform Phase 4 implementation.

## 📁 Available Diagrams

### Core Architecture
- `database-architecture.mmd` - Main system architecture with PostgreSQL, Redis, Elasticsearch
- `multi-country-database.mmd` - Global deployment architecture with US, India, UK regions
- `entity-relationship.mmd` - Database schema relationships with all tables and constraints
- `data-flow.mmd` - Order creation process flow sequence diagram

### Operations & Security
- `security-architecture.mmd` - Security layers and access control with RBAC, encryption, audit
- `monitoring-architecture.mmd` - Observability and monitoring stack with Prometheus, Grafana
- `backup-recovery.mmd` - Disaster recovery and backup strategy
- `scalability-architecture.mmd` - Scaling and performance architecture with partitioning

### Database Design
- `table-structure.mmd` - Database table organization and relationships
- `indexing-strategy.mmd` - Database indexing and optimization strategy

## 🎨 Enhanced Features

All diagrams include enhanced visibility features:

### Visual Improvements
- **Larger Fonts**: Optimized for GitHub preview readability
- **Emojis & Icons**: Visual identification of components (🐘 PostgreSQL, 🔴 Redis, 🔎 Elasticsearch)
- **Color Themes**: Professional color schemes with custom variables
- **Port Numbers**: Clear service identification (Port: 3001, 5432, 6379, 9200)
- **Connection Labels**: Descriptive relationship labels (HTTP/HTTPS, SQL, Redis Protocol)
- **GitHub Preview Optimized**: Enhanced for web viewing

### Theme Configuration
- **Base Theme**: Professional color palette
- **Custom Variables**: Optimized colors for each diagram type
- **Consistent Styling**: Uniform appearance across all diagrams

## 🔧 How to Use

### Mermaid Files (.mmd)
#### Online Viewing
1. **Mermaid Live Editor**: https://mermaid.live/
2. **Copy** the `.mmd` file content
3. **Paste** into the editor
4. **View** with enhanced rendering

#### GitHub Integration
- All diagrams render automatically in GitHub
- Enhanced visibility with larger fonts and colors
- Professional appearance for documentation

#### Local Development
```bash
# Install Mermaid CLI
npm install -g @mermaid-js/mermaid-cli

# Generate SVG
mmdc -i database-architecture.mmd -o database-architecture.svg

# Generate PNG
mmdc -i database-architecture.mmd -o database-architecture.png -w 1920 -H 1080
```

#### VS Code Integration
- Install "Mermaid Preview" extension
- Open `.mmd` files and preview them directly

#### Local Browser Preview
- Use `preview.html` for local viewing
- Run `./scripts/open-preview.sh` to open in browser
- View all diagrams in one place

## 📊 Diagram Types

### Architecture Diagrams
- **System Overview**: Complete platform architecture
- **Multi-Country**: Global deployment strategy
- **Security**: Security layers and compliance
- **Monitoring**: Observability and alerting

### Database Diagrams
- **Entity Relationships**: Table relationships and constraints
- **Data Flow**: Process and data movement
- **Table Structure**: Database organization
- **Indexing**: Performance optimization

### Operations Diagrams
- **Backup & Recovery**: Disaster recovery strategy
- **Scalability**: Performance and scaling architecture
- **Monitoring**: Health and performance monitoring

## 🎯 Best Practices

### For GitHub
- Use emojis for visual identification
- Include port numbers for services
- Add descriptive connection labels
- Optimize for web preview

### For Presentations
- Export as high-resolution PNG using Mermaid CLI
- Use consistent color schemes
- Include clear labels and descriptions
- Maintain professional appearance

### For Development
- Keep diagrams up-to-date
- Use version control for changes
- Document any modifications
- Share with team members

## 🔄 Updates

All diagrams are regularly updated to reflect:
- Architecture changes
- New service additions
- Security enhancements
- Performance optimizations
- Compliance requirements

## 📝 Notes

- All diagrams use enhanced Mermaid syntax
- Optimized for GitHub preview visibility
- Professional styling and colors
- Consistent formatting across all files
- Optimized for both web and print viewing

## 📚 Related Documentation

- `../Phase4-Database-Design.md` - Main database design document
- `../Phase4-Technical-Specifications.md` - Technical specifications
- `../../database/schemas/Phase4-Database-Schema.sql` - SQL schema file
- `conversion-instructions.md` - Instructions for converting to other formats