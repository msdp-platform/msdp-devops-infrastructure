# Phase 4: Database Design - Multi-Service Delivery Platform

## 📋 **Document Overview**

This document provides comprehensive database design specifications for Phase 4 implementation of the multi-service delivery platform, featuring enterprise-scale PostgreSQL architecture with PostGIS support for geospatial operations.

**Version**: 4.0.0  
**Last Updated**: $(date)  
**Database**: PostgreSQL 15+ with PostGIS  
**Architecture**: Modular Microservices  
**Target Scale**: Enterprise (Global Multi-Region)

---

## 🏗️ **Database Architecture Overview**

### **Multi-Country Database Architecture**

```mermaid
graph TB
    subgraph "Global Load Balancer"
        GLOBAL_LB[Global Load Balancer]
        DNS[DNS with Geo-routing]
    end
    
    subgraph "Country: United States"
        subgraph "US-East"
            US_API1[API Gateway US-East]
            US_DB_MASTER[(PostgreSQL Master)]
            US_DB_SLAVE1[(PostgreSQL Slave 1)]
            US_REDIS1[(Redis Cluster)]
            US_ES1[(Elasticsearch)]
        end
        
        subgraph "US-West"
            US_API2[API Gateway US-West]
            US_DB_SLAVE2[(PostgreSQL Slave 2)]
            US_REDIS2[(Redis Cluster)]
            US_ES2[(Elasticsearch)]
        end
    end
    
    subgraph "Country: India"
        subgraph "India-Mumbai"
            IN_API1[API Gateway Mumbai]
            IN_DB_MASTER[(PostgreSQL Master)]
            IN_DB_SLAVE1[(PostgreSQL Slave 1)]
            IN_REDIS1[(Redis Cluster)]
            IN_ES1[(Elasticsearch)]
        end
        
        subgraph "India-Bangalore"
            IN_API2[API Gateway Bangalore]
            IN_DB_SLAVE2[(PostgreSQL Slave 2)]
            IN_REDIS2[(Redis Cluster)]
            IN_ES2[(Elasticsearch)]
        end
    end
    
    subgraph "Country: United Kingdom"
        subgraph "UK-London"
            UK_API1[API Gateway London]
            UK_DB_MASTER[(PostgreSQL Master)]
            UK_DB_SLAVE1[(PostgreSQL Slave 1)]
            UK_REDIS1[(Redis Cluster)]
            UK_ES1[(Elasticsearch)]
        end
    end
    
    subgraph "Global Services"
        GLOBAL_CONFIG[Global Configuration]
        GLOBAL_ANALYTICS[Global Analytics]
        GLOBAL_MONITORING[Global Monitoring]
        CROSS_COUNTRY_SYNC[Cross-Country Sync]
    end
    
    subgraph "Data Replication"
        US_REPLICATION[US Data Replication]
        IN_REPLICATION[India Data Replication]
        UK_REPLICATION[UK Data Replication]
        GLOBAL_SYNC[Global Data Sync]
    end
    
    DNS --> GLOBAL_LB
    GLOBAL_LB --> US_API1
    GLOBAL_LB --> US_API2
    GLOBAL_LB --> IN_API1
    GLOBAL_LB --> IN_API2
    GLOBAL_LB --> UK_API1
    
    US_API1 --> US_DB_MASTER
    US_API2 --> US_DB_SLAVE2
    US_DB_MASTER --> US_DB_SLAVE1
    US_DB_MASTER --> US_DB_SLAVE2
    
    IN_API1 --> IN_DB_MASTER
    IN_API2 --> IN_DB_SLAVE2
    IN_DB_MASTER --> IN_DB_SLAVE1
    IN_DB_MASTER --> IN_DB_SLAVE2
    
    UK_API1 --> UK_DB_MASTER
    UK_DB_MASTER --> UK_DB_SLAVE1
    
    US_DB_MASTER --> US_REPLICATION
    IN_DB_MASTER --> IN_REPLICATION
    UK_DB_MASTER --> UK_REPLICATION
    
    US_REPLICATION --> GLOBAL_SYNC
    IN_REPLICATION --> GLOBAL_SYNC
    UK_REPLICATION --> GLOBAL_SYNC
    
    GLOBAL_SYNC --> GLOBAL_ANALYTICS
    GLOBAL_SYNC --> GLOBAL_MONITORING
```

### **Database Architecture Diagram**

```mermaid
graph TB
    subgraph "Application Layer"
        API[API Gateway]
        AUTH[Authentication Service]
        ORDER[Order Service]
        PAYMENT[Payment Service]
        DELIVERY[Delivery Service]
        NOTIFICATION[Notification Service]
    end
    
    subgraph "Database Layer"
        subgraph "Primary Database"
            POSTGRES[(PostgreSQL 15+<br/>with PostGIS)]
            POSTGRES --> USERS[Users & Roles]
            POSTGRES --> ORDERS[Orders & Items]
            POSTGRES --> MERCHANTS[Merchants & Products]
            POSTGRES --> LOCATIONS[Locations & Zones]
            POSTGRES --> PAYMENTS[Payments]
            POSTGRES --> TRACKING[Delivery Tracking]
            POSTGRES --> REVIEWS[Reviews & Ratings]
            POSTGRES --> NOTIFICATIONS[Notifications]
            POSTGRES --> ANALYTICS[Analytics Events]
        end
        
        subgraph "Cache Layer"
            REDIS[(Redis 7+)]
            REDIS --> SESSIONS[User Sessions]
            REDIS --> CACHE[API Response Cache]
            REDIS --> REALTIME[Real-time Data]
            REDIS --> RATELIMIT[Rate Limiting]
        end
        
        subgraph "Search Engine"
            ELASTIC[(Elasticsearch 8.8+)]
            ELASTIC --> SEARCH_ORDERS[Order Search]
            ELASTIC --> SEARCH_PRODUCTS[Product Search]
            ELASTIC --> SEARCH_MERCHANTS[Merchant Search]
            ELASTIC --> SEARCH_USERS[User Search]
            ELASTIC --> SEARCH_ANALYTICS[Analytics Search]
        end
    end
    
    subgraph "External Services"
        STRIPE[Stripe Payment]
        MAPS[Google Maps API]
        SMS[Twilio SMS]
        EMAIL[SendGrid Email]
    end
    
    API --> POSTGRES
    API --> REDIS
    API --> ELASTIC
    
    AUTH --> POSTGRES
    AUTH --> REDIS
    
    ORDER --> POSTGRES
    ORDER --> REDIS
    ORDER --> ELASTIC
    
    PAYMENT --> POSTGRES
    PAYMENT --> STRIPE
    
    DELIVERY --> POSTGRES
    DELIVERY --> MAPS
    
    NOTIFICATION --> POSTGRES
    NOTIFICATION --> SMS
    NOTIFICATION --> EMAIL
```

### **Multi-Country Database Strategy**

#### **Global Database Architecture**
```yaml
multi_country_strategy:
  approach: "Country-Specific Databases with Global Sync"
  
  countries:
    united_states:
      regions: ["us-east-1", "us-west-2"]
      primary_db: "us-east-1"
      replicas: ["us-west-2"]
      data_residency: "US"
      compliance: ["SOX", "CCPA", "HIPAA"]
    
    india:
      regions: ["ap-south-1", "ap-southeast-1"]
      primary_db: "ap-south-1"
      replicas: ["ap-southeast-1"]
      data_residency: "India"
      compliance: ["IT Act 2000", "DPDP Act"]
    
    united_kingdom:
      regions: ["eu-west-2"]
      primary_db: "eu-west-2"
      replicas: []
      data_residency: "UK"
      compliance: ["GDPR", "UK GDPR"]
  
  global_services:
    analytics: "Cross-country aggregated data"
    monitoring: "Global system health"
    configuration: "Centralized config management"
    user_management: "Global user directory"
```

#### **Data Residency and Compliance**
```yaml
data_residency:
  user_data:
    storage: "Country of registration"
    processing: "Country of operation"
    backup: "Same country + encrypted cross-border"
  
  business_data:
    orders: "Country of merchant"
    payments: "Country of transaction"
    analytics: "Aggregated, anonymized"
  
  compliance_requirements:
    gdpr:
      - Right to erasure
      - Data portability
      - Consent management
      - Breach notification
    
    ccpa:
      - Right to know
      - Right to delete
      - Right to opt-out
      - Non-discrimination
    
    local_laws:
      - Data localization requirements
      - Cross-border data transfer restrictions
      - Government access protocols
```

#### **Cross-Country Data Synchronization**
```yaml
sync_strategy:
  real_time_sync:
    user_profiles: "Immediate sync for global access"
    system_config: "Immediate sync for consistency"
    global_analytics: "Near real-time aggregation"
  
  batch_sync:
    business_metrics: "Daily aggregation"
    compliance_reports: "Weekly sync"
    audit_logs: "Daily sync with encryption"
  
  conflict_resolution:
    user_data: "Last-write-wins with timestamp"
    business_data: "Country-specific rules"
    system_data: "Centralized authority"
```

### **Database Strategy**

#### **Primary Database (PostgreSQL)**
```yaml
database:
  type: PostgreSQL 15+
  purpose: Primary transactional database
  features:
    - ACID compliance
    - Complex queries and transactions
    - JSON/JSONB support
    - Full-text search
    - Geospatial operations (PostGIS)
    - Row-level security
    - Partitioning support
  
  configuration:
    max_connections: 200
    shared_buffers: 256MB
    effective_cache_size: 1GB
    maintenance_work_mem: 64MB
    checkpoint_completion_target: 0.9
    wal_buffers: 16MB
    default_statistics_target: 100
```

#### **Cache Layer (Redis)**
```yaml
redis:
  type: Redis 7+
  purpose: High-performance caching and session storage
  use_cases:
    - Session management
    - API response caching
    - Real-time data storage
    - Rate limiting
    - Pub/sub messaging
    - Temporary data storage
  
  configuration:
    maxmemory: 512mb
    maxmemory-policy: allkeys-lru
    save: "900 1 300 10 60 10000"
```

#### **Search Engine (Elasticsearch)**
```yaml
elasticsearch:
  type: Elasticsearch 8.8+
  purpose: Full-text search and analytics
  indices:
    - orders (order search and filtering)
    - products (product catalog search)
    - merchants (merchant discovery)
    - users (user search for admin)
    - analytics_events (business intelligence)
  
  configuration:
    cluster_name: delivery-platform
    node_name: node-1
    network_host: 0.0.0.0
    http_port: 9200
    discovery_type: single-node
```

---

## 🌍 **Multi-Country Database Implementation**

### **Country-Specific Database Configurations**

#### **United States Configuration**
```yaml
us_database_config:
  regions:
    primary: "us-east-1"
    secondary: "us-west-2"
  
  database_settings:
    timezone: "America/New_York"
    currency: "USD"
    language: "en-US"
    date_format: "MM/DD/YYYY"
  
  compliance:
    - SOX (Sarbanes-Oxley)
    - CCPA (California Consumer Privacy Act)
    - HIPAA (Health Insurance Portability)
    - PCI DSS Level 1
  
  data_retention:
    user_data: "7 years"
    transaction_data: "10 years"
    audit_logs: "7 years"
    analytics_data: "3 years"
  
  backup_strategy:
    frequency: "Every 6 hours"
    retention: "30 days"
    cross_region: "Yes (encrypted)"
    compliance_backup: "Separate encrypted storage"
```

#### **India Configuration**
```yaml
india_database_config:
  regions:
    primary: "ap-south-1"
    secondary: "ap-southeast-1"
  
  database_settings:
    timezone: "Asia/Kolkata"
    currency: "INR"
    language: "en-IN"
    date_format: "DD/MM/YYYY"
  
  compliance:
    - IT Act 2000
    - DPDP Act (Digital Personal Data Protection)
    - RBI Guidelines
    - Local State Regulations
  
  data_retention:
    user_data: "5 years"
    transaction_data: "7 years"
    audit_logs: "5 years"
    analytics_data: "2 years"
  
  backup_strategy:
    frequency: "Every 4 hours"
    retention: "90 days"
    cross_region: "Yes (within India)"
    compliance_backup: "Government-approved storage"
```

#### **United Kingdom Configuration**
```yaml
uk_database_config:
  regions:
    primary: "eu-west-2"
    secondary: "eu-west-1"
  
  database_settings:
    timezone: "Europe/London"
    currency: "GBP"
    language: "en-GB"
    date_format: "DD/MM/YYYY"
  
  compliance:
    - GDPR (General Data Protection Regulation)
    - UK GDPR
    - PECR (Privacy and Electronic Communications)
    - FCA Regulations
  
  data_retention:
    user_data: "6 years"
    transaction_data: "7 years"
    audit_logs: "6 years"
    analytics_data: "2 years"
  
  backup_strategy:
    frequency: "Every 4 hours"
    retention: "60 days"
    cross_region: "Yes (within EU)"
    compliance_backup: "GDPR-compliant storage"
```

### **Cross-Country Data Synchronization Implementation**

#### **Synchronization Tables**
```sql
-- Global user directory for cross-country access
CREATE TABLE global_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    global_user_id UUID UNIQUE NOT NULL,
    country_code VARCHAR(3) NOT NULL,
    local_user_id UUID NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    last_sync_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sync_status VARCHAR(20) DEFAULT 'synced',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cross-country analytics aggregation
CREATE TABLE global_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(100) NOT NULL,
    country_code VARCHAR(3) NOT NULL,
    metric_value DECIMAL(15,2) NOT NULL,
    metric_date DATE NOT NULL,
    aggregation_level VARCHAR(20) NOT NULL, -- daily, weekly, monthly
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(metric_name, country_code, metric_date, aggregation_level)
);

-- Global configuration management
CREATE TABLE global_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    country_code VARCHAR(3), -- NULL for global configs
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **Synchronization Triggers**
```sql
-- Trigger to sync user changes globally
CREATE OR REPLACE FUNCTION sync_user_globally()
RETURNS TRIGGER AS $$
BEGIN
    -- Update global user directory
    INSERT INTO global_users (global_user_id, country_code, local_user_id, email, phone, is_active)
    VALUES (NEW.id, current_setting('app.country_code'), NEW.id, NEW.email, NEW.phone, NEW.is_active)
    ON CONFLICT (global_user_id) 
    DO UPDATE SET 
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        is_active = EXCLUDED.is_active,
        last_sync_at = NOW(),
        sync_status = 'synced';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_user_globally
    AFTER INSERT OR UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION sync_user_globally();
```

### **Data Residency Implementation**

#### **Country-Specific Data Partitioning**
```sql
-- Partition orders by country
CREATE TABLE orders (
    -- ... existing columns ...
    country_code VARCHAR(3) NOT NULL,
    -- ... rest of columns ...
) PARTITION BY LIST (country_code);

-- Create country-specific partitions
CREATE TABLE orders_us PARTITION OF orders
    FOR VALUES IN ('USA');

CREATE TABLE orders_in PARTITION OF orders
    FOR VALUES IN ('IND');

CREATE TABLE orders_uk PARTITION OF orders
    FOR VALUES IN ('GBR');

-- Create indexes on partitioned tables
CREATE INDEX idx_orders_us_customer_id ON orders_us(customer_id);
CREATE INDEX idx_orders_in_customer_id ON orders_in(customer_id);
CREATE INDEX idx_orders_uk_customer_id ON orders_uk(customer_id);
```

#### **Data Localization Policies**
```sql
-- Row Level Security for data residency
CREATE POLICY data_residency_policy ON users
    FOR ALL TO authenticated_users
    USING (
        country_code = current_setting('app.country_code') OR
        current_user_role() IN ('global_admin', 'cross_country_support')
    );

-- Enable RLS on sensitive tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
```

---

## 📊 **Data Model Design**

### **Core Entity Relationships**

```mermaid
erDiagram
    USERS {
        uuid id PK
        string email UK
        string phone UK
        string password_hash
        string first_name
        string last_name
        date date_of_birth
        string profile_image_url
        boolean is_verified
        boolean is_active
        timestamp last_login_at
        timestamp created_at
        timestamp updated_at
        timestamp deleted_at
    }
    
    USER_ROLES {
        uuid id PK
        uuid user_id FK
        enum role
        uuid location_id FK
        uuid granted_by FK
        timestamp granted_at
        timestamp expires_at
        boolean is_active
        timestamp created_at
    }
    
    LOCATIONS {
        uuid id PK
        string name
        enum type
        uuid parent_id FK
        string country_code
        string timezone
        geometry coordinates
        geometry boundary
        jsonb metadata
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }
    
    MERCHANTS {
        uuid id PK
        uuid user_id FK
        string business_name
        enum business_type
        text description
        string logo_url
        string cover_image_url
        uuid location_id FK
        text address
        geometry coordinates
        string phone
        string email
        string website_url
        jsonb business_hours
        boolean is_verified
        boolean is_active
        decimal rating
        integer total_reviews
        timestamp created_at
        timestamp updated_at
    }
    
    PRODUCTS {
        uuid id PK
        uuid merchant_id FK
        uuid category_id FK
        string name
        text description
        decimal price
        decimal compare_price
        decimal cost_price
        string sku
        string barcode
        jsonb images
        jsonb attributes
        integer inventory_quantity
        integer low_stock_threshold
        boolean is_available
        boolean is_featured
        integer sort_order
        timestamp created_at
        timestamp updated_at
    }
    
    ORDERS {
        uuid id PK
        string order_number UK
        uuid customer_id FK
        uuid merchant_id FK
        uuid delivery_partner_id FK
        enum status
        decimal subtotal
        decimal tax_amount
        decimal delivery_fee
        decimal service_fee
        decimal discount_amount
        decimal total_amount
        text delivery_address
        geometry delivery_coordinates
        text delivery_instructions
        timestamp estimated_delivery_time
        timestamp actual_delivery_time
        timestamp order_placed_at
        timestamp accepted_at
        timestamp ready_at
        timestamp picked_up_at
        timestamp delivered_at
        text notes
        jsonb metadata
        timestamp created_at
        timestamp updated_at
    }
    
    ORDER_ITEMS {
        uuid id PK
        uuid order_id FK
        uuid product_id FK
        integer quantity
        decimal unit_price
        decimal total_price
        text special_instructions
        timestamp created_at
    }
    
    PAYMENTS {
        uuid id PK
        uuid order_id FK
        enum payment_method
        enum status
        decimal amount
        string currency
        string gateway_transaction_id
        jsonb gateway_response
        timestamp initiated_at
        timestamp completed_at
        timestamp failed_at
        text failure_reason
        jsonb metadata
        timestamp created_at
        timestamp updated_at
    }
    
    DELIVERY_PARTNERS {
        uuid id PK
        uuid user_id FK
        string vehicle_type
        string vehicle_number
        string license_number
        string insurance_number
        boolean is_verified
        boolean is_available
        geometry current_location
        decimal rating
        integer total_deliveries
        timestamp created_at
        timestamp updated_at
    }
    
    DELIVERY_TRACKING {
        uuid id PK
        uuid order_id FK
        uuid delivery_partner_id FK
        geometry location
        string status
        timestamp timestamp
        decimal accuracy
        decimal speed
        decimal heading
        timestamp created_at
    }
    
    REVIEWS {
        uuid id PK
        uuid order_id FK
        uuid reviewer_id FK
        uuid merchant_id FK
        uuid delivery_partner_id FK
        integer merchant_rating
        integer delivery_rating
        integer food_rating
        text merchant_review
        text delivery_review
        text food_review
        jsonb images
        boolean is_approved
        uuid moderated_by FK
        timestamp moderated_at
        timestamp created_at
        timestamp updated_at
    }
    
    NOTIFICATIONS {
        uuid id PK
        uuid user_id FK
        enum type
        enum channel
        string title
        text message
        jsonb data
        timestamp sent_at
        timestamp delivered_at
        timestamp read_at
        timestamp failed_at
        string status
        integer retry_count
        integer max_retries
        timestamp created_at
        timestamp updated_at
    }
    
    ANALYTICS_EVENTS {
        uuid id PK
        string event_type
        uuid user_id FK
        string session_id
        jsonb properties
        timestamp timestamp
        timestamp created_at
    }

    USERS ||--o{ USER_ROLES : "has roles"
    USERS ||--o{ ORDERS : "places orders"
    USERS ||--o{ MERCHANTS : "owns business"
    USERS ||--o{ DELIVERY_PARTNERS : "is partner"
    USERS ||--o{ REVIEWS : "writes reviews"
    USERS ||--o{ NOTIFICATIONS : "receives"
    USERS ||--o{ ANALYTICS_EVENTS : "generates events"
    
    LOCATIONS ||--o{ LOCATIONS : "parent-child"
    LOCATIONS ||--o{ MERCHANTS : "located in"
    LOCATIONS ||--o{ DELIVERY_ZONES : "contains zones"
    
    MERCHANTS ||--o{ PRODUCTS : "sells products"
    MERCHANTS ||--o{ ORDERS : "receives orders"
    MERCHANTS ||--o{ REVIEWS : "receives reviews"
    
    PRODUCTS ||--o{ ORDER_ITEMS : "included in orders"
    CATEGORIES ||--o{ PRODUCTS : "categorizes"
    
    ORDERS ||--o{ ORDER_ITEMS : "contains items"
    ORDERS ||--o{ PAYMENTS : "has payments"
    ORDERS ||--o{ DELIVERY_TRACKING : "tracks delivery"
    ORDERS ||--o{ REVIEWS : "generates reviews"
    
    DELIVERY_PARTNERS ||--o{ DELIVERY_TRACKING : "tracked by"
    DELIVERY_PARTNERS ||--o{ ORDERS : "delivers orders"
    DELIVERY_PARTNERS ||--o{ REVIEWS : "receives reviews"
```

### **Data Flow Diagram**

```mermaid
sequenceDiagram
    participant C as Customer
    participant API as API Gateway
    participant AUTH as Auth Service
    participant ORDER as Order Service
    participant PAYMENT as Payment Service
    participant DELIVERY as Delivery Service
    participant DB as PostgreSQL
    participant CACHE as Redis
    participant SEARCH as Elasticsearch
    
    Note over C,SEARCH: Order Creation Flow
    
    C->>API: Create Order Request
    API->>AUTH: Validate Token
    AUTH->>CACHE: Check Session
    AUTH-->>API: Token Valid
    
    API->>ORDER: Process Order
    ORDER->>DB: Save Order
    ORDER->>DB: Save Order Items
    ORDER->>CACHE: Cache Order Data
    ORDER->>SEARCH: Index Order
    ORDER-->>API: Order Created
    
    API->>PAYMENT: Process Payment
    PAYMENT->>DB: Save Payment
    PAYMENT->>CACHE: Cache Payment Status
    PAYMENT-->>API: Payment Processed
    
    API->>DELIVERY: Assign Delivery
    DELIVERY->>DB: Update Order Status
    DELIVERY->>CACHE: Update Real-time Status
    DELIVERY-->>API: Delivery Assigned
    
    API-->>C: Order Confirmation
```

### **Entity Descriptions**

#### **1. User Management Entities**

##### **Users Table**
```sql
-- Core user authentication and profile information
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    profile_image_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);
```

**Purpose**: Central user authentication and profile management  
**Key Features**:
- UUID primary key for security
- Soft delete support
- Email and phone uniqueness
- Profile image support
- Verification status tracking

##### **User Roles Table**
```sql
-- Role-based access control (RBAC)
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role user_role_enum NOT NULL,
    location_id UUID, -- For location-specific roles
    granted_by UUID REFERENCES users(id),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Flexible role assignment with location-based permissions  
**Key Features**:
- Multiple roles per user
- Location-specific role assignment
- Role expiration support
- Audit trail with grantor tracking

#### **2. Location Intelligence Entities**

##### **Locations Table**
```sql
-- Geographic hierarchy with PostGIS support
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    type location_type_enum NOT NULL,
    parent_id UUID REFERENCES locations(id),
    country_code VARCHAR(3),
    timezone VARCHAR(50),
    coordinates GEOMETRY(POINT, 4326), -- PostGIS geometry
    boundary GEOMETRY(POLYGON, 4326),  -- For service areas
    metadata JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Hierarchical geographic data with geospatial operations  
**Key Features**:
- PostGIS geometry support
- Hierarchical structure (country → state → district → municipality)
- Timezone information
- Flexible metadata storage
- Boundary definitions for service areas

##### **Delivery Zones Table**
```sql
-- Geofenced delivery areas
CREATE TABLE delivery_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    location_id UUID NOT NULL REFERENCES locations(id),
    zone_boundary GEOMETRY(POLYGON, 4326) NOT NULL,
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    minimum_order_amount DECIMAL(10,2) DEFAULT 0,
    estimated_delivery_time INTEGER, -- in minutes
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Geofenced delivery areas with pricing and timing  
**Key Features**:
- Polygon-based geofencing
- Dynamic pricing per zone
- Minimum order amounts
- Delivery time estimates

#### **3. Merchant Operations Entities**

##### **Merchants Table**
```sql
-- Business information and operations
CREATE TABLE merchants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    business_name VARCHAR(255) NOT NULL,
    business_type business_type_enum NOT NULL,
    description TEXT,
    logo_url TEXT,
    cover_image_url TEXT,
    location_id UUID NOT NULL REFERENCES locations(id),
    address TEXT NOT NULL,
    coordinates GEOMETRY(POINT, 4326),
    phone VARCHAR(20),
    email VARCHAR(255),
    website_url TEXT,
    business_hours JSONB, -- Store operating hours
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    rating DECIMAL(3,2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Business profile and operational information  
**Key Features**:
- Business type categorization
- Geospatial location data
- Operating hours in JSON format
- Rating and review aggregation
- Verification status

##### **Products Table**
```sql
-- Product catalog management
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    compare_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    sku VARCHAR(100),
    barcode VARCHAR(100),
    images JSONB, -- Array of image URLs
    attributes JSONB, -- Product attributes like size, color, etc.
    inventory_quantity INTEGER DEFAULT 0,
    low_stock_threshold INTEGER DEFAULT 5,
    is_available BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Product catalog with inventory management  
**Key Features**:
- Flexible pricing (regular, compare, cost)
- Image gallery support
- Custom attributes in JSON
- Inventory tracking
- Low stock alerts
- Product ordering and featuring

#### **4. Order Management Entities**

##### **Orders Table**
```sql
-- Order lifecycle management
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES users(id),
    merchant_id UUID NOT NULL REFERENCES merchants(id),
    delivery_partner_id UUID REFERENCES users(id),
    status order_status_enum DEFAULT 'pending',
    
    -- Order details
    subtotal DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0,
    delivery_fee DECIMAL(10,2) DEFAULT 0,
    service_fee DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    
    -- Delivery information
    delivery_address TEXT NOT NULL,
    delivery_coordinates GEOMETRY(POINT, 4326),
    delivery_instructions TEXT,
    estimated_delivery_time TIMESTAMP WITH TIME ZONE,
    actual_delivery_time TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    order_placed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    ready_at TIMESTAMP WITH TIME ZONE,
    picked_up_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    notes TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Complete order lifecycle tracking  
**Key Features**:
- Unique order numbering
- Detailed financial breakdown
- Geospatial delivery tracking
- Status-based timestamps
- Flexible metadata storage

##### **Order Items Table**
```sql
-- Individual order line items
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    special_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Individual order line items with pricing  
**Key Features**:
- Product reference with pricing snapshot
- Quantity and pricing calculations
- Special instructions per item
- Cascade delete with orders

#### **5. Payment Processing Entities**

##### **Payments Table**
```sql
-- Payment transaction management
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id),
    payment_method payment_method_enum NOT NULL,
    status payment_status_enum DEFAULT 'pending',
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Payment gateway information
    gateway_transaction_id VARCHAR(255),
    gateway_response JSONB,
    
    -- Timestamps
    initiated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    failure_reason TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Payment processing and transaction tracking  
**Key Features**:
- Multiple payment methods
- Gateway integration support
- Transaction status tracking
- Failure reason logging
- Gateway response storage

#### **6. Delivery Operations Entities**

##### **Delivery Partners Table**
```sql
-- Delivery partner information
CREATE TABLE delivery_partners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    vehicle_type VARCHAR(50), -- bike, car, motorcycle, etc.
    vehicle_number VARCHAR(20),
    license_number VARCHAR(50),
    insurance_number VARCHAR(50),
    is_verified BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT TRUE,
    current_location GEOMETRY(POINT, 4326),
    rating DECIMAL(3,2) DEFAULT 0,
    total_deliveries INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Delivery partner management and tracking  
**Key Features**:
- Vehicle information
- Verification status
- Real-time location tracking
- Performance metrics
- Availability status

##### **Delivery Tracking Table**
```sql
-- Real-time delivery tracking
CREATE TABLE delivery_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id),
    delivery_partner_id UUID NOT NULL REFERENCES delivery_partners(id),
    location GEOMETRY(POINT, 4326) NOT NULL,
    status VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accuracy DECIMAL(8,2), -- GPS accuracy in meters
    speed DECIMAL(8,2),    -- Speed in km/h
    heading DECIMAL(8,2),  -- Direction in degrees
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Real-time GPS tracking and delivery monitoring  
**Key Features**:
- High-frequency location updates
- GPS accuracy tracking
- Speed and direction data
- Status-based tracking
- Historical location data

#### **7. Review and Rating Entities**

##### **Reviews Table**
```sql
-- Customer reviews and ratings
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id),
    reviewer_id UUID NOT NULL REFERENCES users(id),
    merchant_id UUID NOT NULL REFERENCES merchants(id),
    delivery_partner_id UUID REFERENCES delivery_partners(id),
    
    -- Ratings (1-5 scale)
    merchant_rating INTEGER CHECK (merchant_rating >= 1 AND merchant_rating <= 5),
    delivery_rating INTEGER CHECK (delivery_rating >= 1 AND delivery_rating <= 5),
    food_rating INTEGER CHECK (food_rating >= 1 AND food_rating <= 5),
    
    -- Review content
    merchant_review TEXT,
    delivery_review TEXT,
    food_review TEXT,
    
    -- Images
    images JSONB,
    
    -- Moderation
    is_approved BOOLEAN DEFAULT FALSE,
    moderated_by UUID REFERENCES users(id),
    moderated_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Multi-dimensional review system  
**Key Features**:
- Separate ratings for merchant, delivery, and food
- Text reviews for each dimension
- Image support
- Content moderation
- Order-based reviews

#### **8. Notification System Entities**

##### **Notifications Table**
```sql
-- Multi-channel notification system
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    type notification_type_enum NOT NULL,
    channel notification_channel_enum NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB, -- Additional data for the notification
    
    -- Delivery tracking
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending', -- pending, sent, delivered, read, failed
    
    -- Retry logic
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Multi-channel notification delivery and tracking  
**Key Features**:
- Multiple notification types and channels
- Delivery status tracking
- Retry mechanism
- Rich data payload
- Read receipt tracking

#### **9. Analytics and Reporting Entities**

##### **Analytics Events Table**
```sql
-- Event tracking for business intelligence
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    user_id UUID REFERENCES users(id),
    session_id VARCHAR(255),
    properties JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Event tracking for business intelligence  
**Key Features**:
- Flexible event typing
- User and session tracking
- Rich property data
- High-volume event storage

---

## 🔧 **Database Extensions and Features**

### **Table Structure Overview**

```mermaid
graph LR
    subgraph "Core Tables"
        USERS[Users]
        USER_ROLES[User Roles]
        LOCATIONS[Locations]
        DELIVERY_ZONES[Delivery Zones]
    end
    
    subgraph "Business Tables"
        MERCHANTS[Merchants]
        PRODUCTS[Products]
        CATEGORIES[Categories]
        ORDERS[Orders]
        ORDER_ITEMS[Order Items]
    end
    
    subgraph "Payment Tables"
        PAYMENTS[Payments]
        PAYMENT_METHODS[Payment Methods]
    end
    
    subgraph "Delivery Tables"
        DELIVERY_PARTNERS[Delivery Partners]
        DELIVERY_TRACKING[Delivery Tracking]
    end
    
    subgraph "Review Tables"
        REVIEWS[Reviews]
        REVIEW_IMAGES[Review Images]
    end
    
    subgraph "Communication Tables"
        NOTIFICATIONS[Notifications]
        NOTIFICATION_TEMPLATES[Notification Templates]
    end
    
    subgraph "Analytics Tables"
        ANALYTICS_EVENTS[Analytics Events]
        USER_SESSIONS[User Sessions]
    end
    
    USERS --> USER_ROLES
    USERS --> MERCHANTS
    USERS --> ORDERS
    USERS --> DELIVERY_PARTNERS
    USERS --> REVIEWS
    USERS --> NOTIFICATIONS
    USERS --> ANALYTICS_EVENTS
    
    LOCATIONS --> MERCHANTS
    LOCATIONS --> DELIVERY_ZONES
    LOCATIONS --> LOCATIONS
    
    MERCHANTS --> PRODUCTS
    MERCHANTS --> ORDERS
    MERCHANTS --> REVIEWS
    
    PRODUCTS --> ORDER_ITEMS
    CATEGORIES --> PRODUCTS
    
    ORDERS --> ORDER_ITEMS
    ORDERS --> PAYMENTS
    ORDERS --> DELIVERY_TRACKING
    ORDERS --> REVIEWS
    
    DELIVERY_PARTNERS --> DELIVERY_TRACKING
    DELIVERY_PARTNERS --> ORDERS
    DELIVERY_PARTNERS --> REVIEWS
```

### **PostgreSQL Extensions**

#### **Required Extensions**
```sql
-- UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Encryption functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Geospatial operations
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Text search and similarity
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- GIN index support
CREATE EXTENSION IF NOT EXISTS "btree_gin";
```

### **Custom Types and Enums**

#### **User Role Enum**
```sql
CREATE TYPE user_role_enum AS ENUM (
    'customer',
    'merchant',
    'delivery_partner',
    'admin',
    'super_admin',
    'support_staff',
    'country_distributor',
    'regional_manager',
    'district_manager',
    'municipal_manager'
);
```

#### **Location Type Enum**
```sql
CREATE TYPE location_type_enum AS ENUM (
    'country',
    'state',
    'district',
    'municipality',
    'service_area',
    'delivery_zone'
);
```

#### **Order Status Enum**
```sql
CREATE TYPE order_status_enum AS ENUM (
    'pending',
    'accepted',
    'preparing',
    'ready_for_pickup',
    'picked_up',
    'in_transit',
    'delivered',
    'cancelled',
    'refunded',
    'disputed'
);
```

---

## 📈 **Performance Optimization**

### **Indexing Strategy Diagram**

```mermaid
graph TB
    subgraph "Primary Indexes"
        USER_EMAIL[Users: email]
        USER_PHONE[Users: phone]
        USER_CREATED[Users: created_at]
        
        ORDER_CUSTOMER[Orders: customer_id]
        ORDER_MERCHANT[Orders: merchant_id]
        ORDER_STATUS[Orders: status]
        ORDER_CREATED[Orders: created_at]
        
        PRODUCT_MERCHANT[Products: merchant_id]
        PRODUCT_CATEGORY[Products: category_id]
        PRODUCT_NAME[Products: name - GIN]
        
        LOCATION_TYPE[Locations: type]
        LOCATION_PARENT[Locations: parent_id]
        LOCATION_COORDS[Locations: coordinates - GIST]
    end
    
    subgraph "Composite Indexes"
        ORDER_CUSTOMER_STATUS[Orders: customer_id + status]
        ORDER_MERCHANT_STATUS[Orders: merchant_id + status]
        ORDER_STATUS_CREATED[Orders: status + created_at]
        PRODUCT_MERCHANT_AVAILABLE[Products: merchant_id + is_available]
    end
    
    subgraph "Geospatial Indexes"
        DELIVERY_ZONES_BOUNDARY[Delivery Zones: boundary - GIST]
        DELIVERY_TRACKING_LOCATION[Delivery Tracking: location - GIST]
        ORDERS_DELIVERY_COORDS[Orders: delivery_coordinates - GIST]
    end
    
    subgraph "Text Search Indexes"
        PRODUCTS_NAME_TRGM[Products: name - pg_trgm]
        MERCHANTS_NAME_TRGM[Merchants: business_name - pg_trgm]
        REVIEWS_TEXT_TRGM[Reviews: review_text - pg_trgm]
    end
    
    USER_EMAIL --> QUERY_PERF[Query Performance]
    ORDER_CUSTOMER_STATUS --> QUERY_PERF
    LOCATION_COORDS --> QUERY_PERF
    PRODUCTS_NAME_TRGM --> QUERY_PERF
```

### **Indexing Strategy**

#### **Primary Indexes**
```sql
-- User indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Location indexes
CREATE INDEX idx_locations_type ON locations(type);
CREATE INDEX idx_locations_parent_id ON locations(parent_id);
CREATE INDEX idx_locations_coordinates ON locations USING GIST(coordinates);
CREATE INDEX idx_delivery_zones_boundary ON delivery_zones USING GIST(zone_boundary);

-- Order indexes
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_merchant_id ON orders(merchant_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_orders_delivery_coordinates ON orders USING GIST(delivery_coordinates);

-- Product indexes
CREATE INDEX idx_products_merchant_id ON products(merchant_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_name ON products USING GIN(name gin_trgm_ops);

-- Delivery tracking indexes
CREATE INDEX idx_delivery_tracking_order_id ON delivery_tracking(order_id);
CREATE INDEX idx_delivery_tracking_timestamp ON delivery_tracking(timestamp);
CREATE INDEX idx_delivery_tracking_location ON delivery_tracking USING GIST(location);
```

#### **Composite Indexes**
```sql
-- Multi-column indexes for common queries
CREATE INDEX idx_orders_customer_status ON orders(customer_id, status);
CREATE INDEX idx_orders_merchant_status ON orders(merchant_id, status);
CREATE INDEX idx_orders_status_created ON orders(status, created_at);
CREATE INDEX idx_products_merchant_available ON products(merchant_id, is_available);
CREATE INDEX idx_delivery_tracking_order_timestamp ON delivery_tracking(order_id, timestamp);
```

### **Query Optimization**

#### **Common Query Patterns**
```sql
-- Active orders for a customer
SELECT o.*, m.business_name, dp.first_name || ' ' || dp.last_name as delivery_partner_name
FROM orders o
JOIN merchants m ON o.merchant_id = m.id
LEFT JOIN users dp ON o.delivery_partner_id = dp.id
WHERE o.customer_id = $1 
  AND o.status NOT IN ('delivered', 'cancelled', 'refunded')
ORDER BY o.created_at DESC;

-- Nearby merchants
SELECT m.*, ST_Distance(m.coordinates, ST_Point($1, $2)) as distance
FROM merchants m
WHERE ST_DWithin(m.coordinates, ST_Point($1, $2), $3)
  AND m.is_active = true
  AND m.is_verified = true
ORDER BY distance;

-- Delivery partner performance
SELECT 
    dp.id,
    dp.user_id,
    COUNT(o.id) as total_deliveries,
    AVG(EXTRACT(EPOCH FROM (o.delivered_at - o.picked_up_at))/60) as avg_delivery_time_minutes,
    AVG(r.delivery_rating) as avg_rating
FROM delivery_partners dp
LEFT JOIN orders o ON dp.user_id = o.delivery_partner_id AND o.status = 'delivered'
LEFT JOIN reviews r ON dp.user_id = r.delivery_partner_id
WHERE dp.is_active = true
GROUP BY dp.id, dp.user_id;
```

---

## 🔒 **Security and Compliance**

### **Security Architecture Diagram**

```mermaid
graph TB
    subgraph "Application Layer"
        CLIENT[Client Applications]
        API_GW[API Gateway]
        AUTH_SVC[Authentication Service]
    end
    
    subgraph "Database Security Layer"
        subgraph "Access Control"
            RBAC[Role-Based Access Control]
            RLS[Row Level Security]
            PERMISSIONS[Permission Matrix]
        end
        
        subgraph "Data Protection"
            ENCRYPTION[Data Encryption]
            HASHING[Password Hashing]
            AUDIT[Audit Trail]
        end
        
        subgraph "Network Security"
            TLS[TLS 1.3]
            VPN[VPN Access]
            FIREWALL[Database Firewall]
        end
    end
    
    subgraph "Database Layer"
        POSTGRES[(PostgreSQL)]
        REDIS[(Redis)]
        ELASTIC[(Elasticsearch)]
    end
    
    subgraph "Monitoring & Compliance"
        LOGGING[Security Logging]
        MONITORING[Real-time Monitoring]
        COMPLIANCE[Compliance Checks]
    end
    
    CLIENT --> API_GW
    API_GW --> AUTH_SVC
    AUTH_SVC --> RBAC
    RBAC --> RLS
    RLS --> PERMISSIONS
    
    API_GW --> TLS
    TLS --> FIREWALL
    FIREWALL --> POSTGRES
    
    POSTGRES --> ENCRYPTION
    POSTGRES --> HASHING
    POSTGRES --> AUDIT
    
    AUDIT --> LOGGING
    LOGGING --> MONITORING
    MONITORING --> COMPLIANCE
```

### **Row Level Security (RLS)**

#### **User Data Protection**
```sql
-- Enable RLS on sensitive tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- User access policy
CREATE POLICY user_access_policy ON users
    FOR ALL TO authenticated_users
    USING (id = current_user_id());

-- Admin access policy
CREATE POLICY admin_access_policy ON users
    FOR ALL TO admin_users
    USING (true);
```

### **Data Encryption**

#### **Sensitive Data Encryption**
```sql
-- Encrypt sensitive fields
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(data TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_encrypt(data, current_setting('app.encryption_key'));
END;
$$ LANGUAGE plpgsql;

-- Decrypt sensitive data
CREATE OR REPLACE FUNCTION decrypt_sensitive_data(encrypted_data TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(encrypted_data, current_setting('app.encryption_key'));
END;
$$ LANGUAGE plpgsql;
```

### **Audit Trail**

#### **Audit Trigger Function**
```sql
-- Audit trail function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (
        table_name,
        operation,
        old_data,
        new_data,
        changed_by,
        changed_at
    ) VALUES (
        TG_TABLE_NAME,
        TG_OP,
        CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN row_to_json(NEW) ELSE NULL END,
        current_user,
        NOW()
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers
CREATE TRIGGER users_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
```

---

## 📊 **Data Views and Reporting**

### **Business Intelligence Views**

#### **Active Orders View**
```sql
CREATE VIEW active_orders AS
SELECT 
    o.*,
    u.first_name || ' ' || u.last_name as customer_name,
    u.phone as customer_phone,
    m.business_name as merchant_name,
    m.phone as merchant_phone,
    dp.first_name || ' ' || dp.last_name as delivery_partner_name,
    dp.phone as delivery_partner_phone,
    ST_AsText(o.delivery_coordinates) as delivery_location
FROM orders o
JOIN users u ON o.customer_id = u.id
JOIN merchants m ON o.merchant_id = m.id
LEFT JOIN users dp ON o.delivery_partner_id = dp.id
WHERE o.status NOT IN ('delivered', 'cancelled', 'refunded');
```

#### **Merchant Performance View**
```sql
CREATE VIEW merchant_performance AS
SELECT 
    m.id,
    m.business_name,
    m.business_type,
    m.location_id,
    COUNT(o.id) as total_orders,
    COUNT(CASE WHEN o.status = 'delivered' THEN 1 END) as completed_orders,
    COUNT(CASE WHEN o.status = 'cancelled' THEN 1 END) as cancelled_orders,
    AVG(r.merchant_rating) as avg_rating,
    SUM(CASE WHEN o.status = 'delivered' THEN o.total_amount ELSE 0 END) as total_revenue,
    AVG(CASE WHEN o.status = 'delivered' 
        THEN EXTRACT(EPOCH FROM (o.delivered_at - o.order_placed_at))/60 
        END) as avg_delivery_time_minutes
FROM merchants m
LEFT JOIN orders o ON m.id = o.merchant_id
LEFT JOIN reviews r ON m.id = r.merchant_id
GROUP BY m.id, m.business_name, m.business_type, m.location_id;
```

#### **Delivery Partner Performance View**
```sql
CREATE VIEW delivery_partner_performance AS
SELECT 
    dp.id,
    dp.user_id,
    u.first_name || ' ' || u.last_name as partner_name,
    dp.vehicle_type,
    dp.is_available,
    COUNT(o.id) as total_deliveries,
    COUNT(CASE WHEN o.status = 'delivered' THEN 1 END) as completed_deliveries,
    AVG(r.delivery_rating) as avg_rating,
    AVG(CASE WHEN o.status = 'delivered' 
        THEN EXTRACT(EPOCH FROM (o.delivered_at - o.picked_up_at))/60 
        END) as avg_delivery_time_minutes,
    SUM(CASE WHEN o.status = 'delivered' THEN o.delivery_fee ELSE 0 END) as total_earnings
FROM delivery_partners dp
JOIN users u ON dp.user_id = u.id
LEFT JOIN orders o ON dp.user_id = o.delivery_partner_id
LEFT JOIN reviews r ON dp.user_id = r.delivery_partner_id
GROUP BY dp.id, dp.user_id, u.first_name, u.last_name, dp.vehicle_type, dp.is_available;
```

---

## 🔄 **Data Migration and Versioning**

### **Migration Strategy**

#### **Database Versioning**
```sql
-- Migration tracking table
CREATE TABLE schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    description TEXT
);

-- Insert initial migration
INSERT INTO schema_migrations (version, description) 
VALUES ('20240101000001', 'Initial schema creation');
```

#### **Data Seeding**

##### **Default Permissions**
```sql
-- Insert default permissions
INSERT INTO permissions (name, description, resource, action) VALUES
('user:read', 'Read user information', 'user', 'read'),
('user:write', 'Modify user information', 'user', 'write'),
('order:create', 'Create new orders', 'order', 'create'),
('order:read', 'Read order information', 'order', 'read'),
('order:update', 'Update order status', 'order', 'update'),
('merchant:manage', 'Manage merchant operations', 'merchant', 'manage'),
('delivery:assign', 'Assign delivery partners', 'delivery', 'assign'),
('analytics:read', 'Read analytics data', 'analytics', 'read'),
('admin:full', 'Full administrative access', 'admin', 'full');
```

##### **Default Categories**
```sql
-- Insert default product categories
INSERT INTO categories (name, description) VALUES
('Food & Beverage', 'Restaurants, cafes, and food delivery'),
('Grocery', 'Grocery stores and supermarkets'),
('Pharmacy', 'Pharmacies and health products'),
('Retail', 'General retail and shopping'),
('Services', 'Various service providers'),
('Beauty & Wellness', 'Beauty salons and wellness services'),
('Education', 'Educational services and tutoring'),
('Healthcare', 'Healthcare and medical services');
```

---

## 📈 **Monitoring and Maintenance**

### **Monitoring Architecture Diagram**

```mermaid
graph TB
    subgraph "Application Layer"
        APP1[Application 1]
        APP2[Application 2]
        APP3[Application 3]
    end
    
    subgraph "Database Layer"
        POSTGRES[(PostgreSQL)]
        REDIS[(Redis)]
        ELASTIC[(Elasticsearch)]
    end
    
    subgraph "Monitoring Stack"
        PROMETHEUS[Prometheus]
        GRAFANA[Grafana]
        ALERTMANAGER[Alert Manager]
        JAEGER[Jaeger Tracing]
    end
    
    subgraph "Logging Stack"
        FILEBEAT[Filebeat]
        LOGSTASH[Logstash]
        ELASTICSEARCH_LOGS[Elasticsearch Logs]
        KIBANA[Kibana]
    end
    
    subgraph "Alerting"
        SLACK[Slack]
        EMAIL[Email]
        PAGERDUTY[PagerDuty]
        WEBHOOK[Webhook]
    end
    
    APP1 --> POSTGRES
    APP2 --> REDIS
    APP3 --> ELASTIC
    
    POSTGRES --> PROMETHEUS
    REDIS --> PROMETHEUS
    ELASTIC --> PROMETHEUS
    
    PROMETHEUS --> GRAFANA
    PROMETHEUS --> ALERTMANAGER
    
    APP1 --> JAEGER
    APP2 --> JAEGER
    APP3 --> JAEGER
    
    APP1 --> FILEBEAT
    APP2 --> FILEBEAT
    APP3 --> FILEBEAT
    
    FILEBEAT --> LOGSTASH
    LOGSTASH --> ELASTICSEARCH_LOGS
    ELASTICSEARCH_LOGS --> KIBANA
    
    ALERTMANAGER --> SLACK
    ALERTMANAGER --> EMAIL
    ALERTMANAGER --> PAGERDUTY
    ALERTMANAGER --> WEBHOOK
```

### **Database Monitoring**

#### **Performance Metrics**
```sql
-- Query performance monitoring
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- Table size monitoring
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

#### **Index Usage Monitoring**
```sql
-- Index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_tup_read DESC;
```

### **Maintenance Tasks**

#### **Vacuum and Analyze**
```sql
-- Automated maintenance
CREATE OR REPLACE FUNCTION maintenance_routine()
RETURNS void AS $$
BEGIN
    -- Vacuum all tables
    VACUUM ANALYZE;
    
    -- Update statistics
    ANALYZE;
    
    -- Reindex if needed
    REINDEX DATABASE delivery_platform;
END;
$$ LANGUAGE plpgsql;
```

---

## 🚀 **Scalability Considerations**

### **Scalability Architecture Diagram**

```mermaid
graph TB
    subgraph "Load Balancer Layer"
        LB[Load Balancer]
        CDN[CDN]
    end
    
    subgraph "Application Layer"
        API1[API Gateway 1]
        API2[API Gateway 2]
        API3[API Gateway 3]
    end
    
    subgraph "Database Layer"
        subgraph "Primary Database"
            MASTER[(PostgreSQL Master)]
            SLAVE1[(PostgreSQL Slave 1)]
            SLAVE2[(PostgreSQL Slave 2)]
            SLAVE3[(PostgreSQL Slave 3)]
        end
        
        subgraph "Cache Layer"
            REDIS1[(Redis Cluster 1)]
            REDIS2[(Redis Cluster 2)]
            REDIS3[(Redis Cluster 3)]
        end
        
        subgraph "Search Layer"
            ES1[(Elasticsearch Node 1)]
            ES2[(Elasticsearch Node 2)]
            ES3[(Elasticsearch Node 3)]
        end
    end
    
    subgraph "Partitioning Strategy"
        ORDERS_2024[Orders 2024]
        ORDERS_2025[Orders 2025]
        TRACKING_W1[Tracking Week 1]
        TRACKING_W2[Tracking Week 2]
    end
    
    LB --> API1
    LB --> API2
    LB --> API3
    
    API1 --> MASTER
    API2 --> SLAVE1
    API3 --> SLAVE2
    
    MASTER --> SLAVE1
    MASTER --> SLAVE2
    MASTER --> SLAVE3
    
    API1 --> REDIS1
    API2 --> REDIS2
    API3 --> REDIS3
    
    API1 --> ES1
    API2 --> ES2
    API3 --> ES3
    
    MASTER --> ORDERS_2024
    MASTER --> ORDERS_2025
    MASTER --> TRACKING_W1
    MASTER --> TRACKING_W2
```

### **Partitioning Strategy**

#### **Time-Based Partitioning**
```sql
-- Partition orders table by month
CREATE TABLE orders_2024_01 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Partition delivery_tracking by week
CREATE TABLE delivery_tracking_2024_w01 PARTITION OF delivery_tracking
    FOR VALUES FROM ('2024-01-01') TO ('2024-01-08');
```

### **Read Replicas**

#### **Replica Configuration**
```yaml
read_replicas:
  analytics_replica:
    purpose: Business intelligence queries
    lag_tolerance: 5 minutes
    query_types: [SELECT, ANALYZE]
  
  reporting_replica:
    purpose: Report generation
    lag_tolerance: 15 minutes
    query_types: [SELECT, ANALYZE]
```

---

## 📋 **Backup and Recovery**

### **Backup and Recovery Architecture Diagram**

```mermaid
graph TB
    subgraph "Production Environment"
        POSTGRES_PROD[(PostgreSQL Production)]
        REDIS_PROD[(Redis Production)]
        ELASTIC_PROD[(Elasticsearch Production)]
    end
    
    subgraph "Backup Strategy"
        DAILY_BACKUP[Daily Full Backup]
        HOURLY_BACKUP[Hourly Incremental]
        WAL_ARCHIVE[WAL Archive]
        REDIS_BACKUP[Redis Backup]
        ES_BACKUP[Elasticsearch Backup]
    end
    
    subgraph "Storage Layer"
        S3_PRIMARY[S3 Primary]
        S3_SECONDARY[S3 Secondary]
        GLACIER[Glacier Archive]
    end
    
    subgraph "Recovery Environment"
        POSTGRES_RECOVERY[(PostgreSQL Recovery)]
        REDIS_RECOVERY[(Redis Recovery)]
        ES_RECOVERY[(Elasticsearch Recovery)]
    end
    
    subgraph "Monitoring"
        BACKUP_MONITOR[Backup Monitoring]
        RECOVERY_TEST[Recovery Testing]
        ALERT_SYSTEM[Alert System]
    end
    
    POSTGRES_PROD --> DAILY_BACKUP
    POSTGRES_PROD --> HOURLY_BACKUP
    POSTGRES_PROD --> WAL_ARCHIVE
    
    REDIS_PROD --> REDIS_BACKUP
    ELASTIC_PROD --> ES_BACKUP
    
    DAILY_BACKUP --> S3_PRIMARY
    HOURLY_BACKUP --> S3_PRIMARY
    WAL_ARCHIVE --> S3_PRIMARY
    REDIS_BACKUP --> S3_PRIMARY
    ES_BACKUP --> S3_PRIMARY
    
    S3_PRIMARY --> S3_SECONDARY
    S3_SECONDARY --> GLACIER
    
    S3_PRIMARY --> POSTGRES_RECOVERY
    S3_PRIMARY --> REDIS_RECOVERY
    S3_PRIMARY --> ES_RECOVERY
    
    DAILY_BACKUP --> BACKUP_MONITOR
    HOURLY_BACKUP --> BACKUP_MONITOR
    WAL_ARCHIVE --> BACKUP_MONITOR
    
    BACKUP_MONITOR --> ALERT_SYSTEM
    RECOVERY_TEST --> ALERT_SYSTEM
```

### **Backup Strategy**

#### **Automated Backups**
```bash
#!/bin/bash
# Daily backup script
pg_dump -h localhost -U delivery_user -d delivery_platform \
  --format=custom \
  --compress=9 \
  --file=backup_$(date +%Y%m%d_%H%M%S).dump

# Upload to S3
aws s3 cp backup_$(date +%Y%m%d_%H%M%S).dump s3://delivery-platform-backups/
```

#### **Point-in-Time Recovery**
```sql
-- Enable WAL archiving
archive_mode = on
archive_command = 'aws s3 cp %p s3://delivery-platform-wal/%f'
wal_level = replica
max_wal_senders = 3
```

---

## 📝 **Conclusion**

This database design provides a robust foundation for Phase 4 implementation with:

- **Enterprise-scale architecture** with PostgreSQL and PostGIS
- **Comprehensive data models** for all business operations
- **Performance optimization** with strategic indexing
- **Security features** with RLS and encryption
- **Scalability support** with partitioning and read replicas
- **Monitoring and maintenance** capabilities
- **Backup and recovery** strategies

**Key Implementation Priorities:**
1. **Core tables** (users, orders, merchants, products)
2. **Geospatial features** (locations, delivery zones, tracking)
3. **Performance optimization** (indexes, views, queries)
4. **Security implementation** (RLS, encryption, audit)
5. **Monitoring setup** (metrics, alerts, maintenance)

**Next Steps:**
1. Review and approve database design
2. Set up development database environment
3. Implement core tables and relationships
4. Add geospatial features and PostGIS support
5. Configure security and monitoring

---

**Document Version**: 4.0.0  
**Last Updated**: $(date)  
**Next Review**: $(date +30 days)
