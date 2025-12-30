# InfluxDB v.3 Core Documentation Index

**Document Created:** December 10, 2025  
**Documentation Source:** https://docs.influxdata.com/influxdb3/core/  
**Status:** ✅ Successfully researched and indexed

## Table of Contents

1. [Overview](#overview)
2. [Main Documentation Sections](#main-documentation-sections)
3. [Getting Started](#getting-started)
4. [Write Data](#write-data)
5. [Query Data](#query-data)
6. [Processing Engine & Python Plugins](#processing-engine--python-plugins)
7. [Visualize Data](#visualize-data)
8. [Administration](#administration)
9. [Reference](#reference)
10. [Additional Resources](#additional-resources)

---

## Overview

**Home:** https://docs.influxdata.com/influxdb3/core/

InfluxDB 3 Core is a purpose-built database for collecting, processing, transforming, and storing event and time series data. It's ideal for use cases requiring real-time ingest and fast query response times.

### Key Features
- Diskless architecture with object storage support
- Fast query response times (under 10ms for last-value queries)
- Embedded Python VM for plugins and triggers
- Parquet file persistence
- Compatibility with InfluxDB 1.x and 2.x write APIs

### Version Information
- **Current Version:** InfluxDB 3.7
- **Release Date:** Latest 2025
- **Docker Image:** `influxdb:3-core`

---

## Main Documentation Sections

### 1. Installation
- **Link:** https://docs.influxdata.com/influxdb3/core/install/
- **Topics:**
  - System Requirements (Linux, macOS, Windows)
  - Object Storage Configuration
  - Quick install for Linux and macOS
  - Download and install build artifacts
  - Pull Docker image
  - Verification

### 2. Get Started
- **Link:** https://docs.influxdata.com/influxdb3/core/get-started/
- **Subtopics:**
  - [Set up InfluxDB 3 Core](#get-started-setup)
  - [Write data to InfluxDB 3 Core](#get-started-write)
  - [Query data in InfluxDB 3 Core](#get-started-query)
  - [Process data in InfluxDB 3 Core](#get-started-process)

---

## Getting Started

### Get Started - Setup
- **Link:** https://docs.influxdata.com/influxdb3/core/get-started/setup/
- **Topics:**
  - Data model overview
  - Database and table structure
  - Column types (tags, fields, time)
  - Primary key configuration
  - Available tools and their capabilities

### Get Started - Write Data
- **Link:** https://docs.influxdata.com/influxdb3/core/get-started/write/
- **Topics:**
  - Writing data to InfluxDB
  - Tool selection for writing

### Get Started - Query Data
- **Link:** https://docs.influxdata.com/influxdb3/core/get-started/query/
- **Topics:**
  - Querying data from InfluxDB
  - Query tools and methods

### Get Started - Process Data
- **Link:** https://docs.influxdata.com/influxdb3/core/get-started/process/
- **Topics:**
  - Data processing capabilities
  - Python plugin integration

---

## Write Data

### Main Write Data Section
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/

### Client Libraries
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/client-libraries/

### HTTP API
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/http-api/
- **Subtopics:**
  - [v3 write_lp API](#http-api-v3-write-lp)
  - [v1 and v2 compatibility APIs](#http-api-compatibility)

#### v3 write_lp API
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/http-api/v3-write-lp/

#### v1 and v2 Compatibility APIs
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/http-api/compatibility-apis/

### Telegraf Integration
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/use-telegraf/
- **Subtopics:**
  - [Configure Telegraf](#telegraf-configure)
  - [Dual write to InfluxDB](#telegraf-dual-write)
  - [Write CSV](#telegraf-csv)

#### Configure Telegraf
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/use-telegraf/configure/

#### Dual Write to InfluxDB
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/use-telegraf/dual-write/

#### Write CSV
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/use-telegraf/csv/

### influxdb3 CLI
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/influxdb3-cli/

### Best Practices
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/best-practices/
- **Subtopics:**
  - [Schema Design](#best-practices-schema)
  - [Optimize Writes](#best-practices-optimize)

#### Schema Design
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/best-practices/schema-design/

#### Optimize Writes
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/best-practices/optimize-writes/

### Troubleshooting
- **Link:** https://docs.influxdata.com/influxdb3/core/write-data/troubleshoot/

---

## Query Data

### Main Query Data Section
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/

### Execute Queries
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/execute-queries/
- **Subtopics:**
  - [influxdb3 CLI](#execute-influxdb3-cli)
  - [v3 query API](#execute-v3-api)
  - [v1 query API](#execute-v1-api)

#### influxdb3 CLI
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/execute-queries/influxdb3-cli/

#### v3 Query API
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/execute-queries/influxdb-v3-api/

#### v1 Query API
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/execute-queries/influxdb-v1-api/

### Query with SQL
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/sql/
- **Subtopics:**
  - [Explore your schema](#sql-explore-schema)
  - [Basic query](#sql-basic-query)
  - [Aggregate data](#sql-aggregate)
  - [Cast types](#sql-cast-types)
  - [Compare values](#sql-compare-values)
  - [Fill gaps in data](#sql-fill-gaps)
  - [Parameterized queries](#sql-parameterized)

#### SQL - Explore Your Schema
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/sql/explore-schema/

#### SQL - Basic Query
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/sql/basic-query/

#### SQL - Aggregate Data
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/sql/aggregate-select/

#### SQL - Cast Types
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/sql/cast-types/

#### SQL - Compare Values
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/sql/compare-values/

#### SQL - Fill Gaps in Data
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/sql/fill-gaps/

#### SQL - Parameterized Queries
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/sql/parameterized-queries/

### Query with InfluxQL
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/influxql/
- **Subtopics:**
  - [Explore your schema](#influxql-explore-schema)
  - [Basic query](#influxql-basic-query)
  - [Aggregate data](#influxql-aggregate)
  - [Troubleshoot errors](#influxql-troubleshoot)

#### InfluxQL - Explore Your Schema
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/influxql/explore-schema/

#### InfluxQL - Basic Query
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/influxql/basic-query/

#### InfluxQL - Aggregate Data
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/influxql/aggregate-select/

#### InfluxQL - Troubleshoot Errors
- **Link:** https://docs.influxdata.com/influxdb3/core/query-data/influxql/troubleshoot/

---

## Visualize Data

- **Main Link:** https://docs.influxdata.com/influxdb3/core/visualize-data/

### Grafana Integration
- **Link:** https://docs.influxdata.com/influxdb3/core/visualize-data/grafana/

### Power BI Integration
- **Link:** https://docs.influxdata.com/influxdb3/core/visualize-data/powerbi/

---

## Processing Engine & Python Plugins

- **Main Link:** https://docs.influxdata.com/influxdb3/core/plugins/

### Extend Plugins
- **Link:** https://docs.influxdata.com/influxdb3/core/plugins/extend-plugin/

### Plugin Library
- **Link:** https://docs.influxdata.com/influxdb3/core/plugins/library/

#### Example Plugins
- **Link:** https://docs.influxdata.com/influxdb3/core/plugins/library/examples/
- **Example:** WAL Plugin
  - **Link:** https://docs.influxdata.com/influxdb3/core/plugins/library/examples/wal-plugin/

#### Official Plugins
- **Link:** https://docs.influxdata.com/influxdb3/core/plugins/library/official/

**Available Official Plugins:**

1. **Basic Transformation**
   - Link: https://docs.influxdata.com/influxdb3/core/plugins/library/official/basic-transformation/

2. **Downsampler**
   - Link: https://docs.influxdata.com/influxdb3/core/plugins/library/official/downsampler/

3. **Forecast Error Evaluator**
   - Link: https://docs.influxdata.com/influxdb3/core/plugins/library/official/forecast-error-evaluator/

4. **InfluxDB to Iceberg**
   - Link: https://docs.influxdata.com/influxdb3/core/plugins/library/official/influxdb-to-iceberg/

5. **MAD Anomaly Detection**
   - Link: https://docs.influxdata.com/influxdb3/core/plugins/library/official/mad-anomaly-detection/

6. **Notifier**
   - Link: https://docs.influxdata.com/influxdb3/core/plugins/library/official/notifier/

7. **Prophet Forecasting**
   - Link: https://docs.influxdata.com/influxdb3/core/plugins/library/official/prophet-forecasting/

8. **State Change**
   - Link: https://docs.influxdata.com/influxdb3/core/plugins/library/official/state-change/

9. **Stateless ADTK Detector**
   - Link: https://docs.influxdata.com/influxdb3/core/plugins/library/official/stateless-adtk-detector/

10. **System Metrics**
    - Link: https://docs.influxdata.com/influxdb3/core/plugins/library/official/system-metrics/

11. **Threshold Deadman Checks**
    - Link: https://docs.influxdata.com/influxdb3/core/plugins/library/official/threshold-deadman-checks/

---

## Administration

- **Main Link:** https://docs.influxdata.com/influxdb3/core/admin/

### Identify Version
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/identify-version/

### Manage Databases
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/databases/
- **Subtopics:**
  - [Create a database](#admin-db-create)
  - [List databases](#admin-db-list)
  - [Delete a database](#admin-db-delete)

#### Create a Database
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/databases/create/

#### List Databases
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/databases/list/

#### Delete a Database
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/databases/delete/

### Manage Tables
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/tables/
- **Subtopics:**
  - [Create a table](#admin-table-create)
  - [List tables](#admin-table-list)
  - [Delete a table](#admin-table-delete)

#### Create a Table
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/tables/create/

#### List Tables
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/tables/list/

#### Delete a Table
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/tables/delete/

### Manage Tokens
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/tokens/

#### Admin Tokens
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/tokens/admin/

**Admin Token Operations:**
- [Create an admin token](https://docs.influxdata.com/influxdb3/core/admin/tokens/admin/create/)
- [List admin tokens](https://docs.influxdata.com/influxdb3/core/admin/tokens/admin/list/)
- [Regenerate an admin token](https://docs.influxdata.com/influxdb3/core/admin/tokens/admin/regenerate/)
- [Use preconfigured admin token](https://docs.influxdata.com/influxdb3/core/admin/tokens/admin/preconfigured/)

### Manage the Last Value Cache
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/last-value-cache/
- **Subtopics:**
  - [Create a Last Value Cache](#lvc-create)
  - [Query a Last Value Cache](#lvc-query)
  - [Show Last Value Caches](#lvc-show)
  - [Delete a Last Value Cache](#lvc-delete)

#### Create a Last Value Cache
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/last-value-cache/create/

#### Query a Last Value Cache
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/last-value-cache/query/

#### Show Last Value Caches
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/last-value-cache/show/

#### Delete a Last Value Cache
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/last-value-cache/delete/

### Manage the Distinct Value Cache
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/distinct-value-cache/
- **Subtopics:**
  - [Create a Distinct Value Cache](#dvc-create)
  - [Query a Distinct Value Cache](#dvc-query)
  - [Show Distinct Value Caches](#dvc-show)
  - [Delete a Distinct Value Cache](#dvc-delete)

#### Create a Distinct Value Cache
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/distinct-value-cache/create/

#### Query a Distinct Value Cache
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/distinct-value-cache/query/

#### Show Distinct Value Caches
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/distinct-value-cache/show/

#### Delete a Distinct Value Cache
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/distinct-value-cache/delete/

### Configure Object Storage
- **Link:** https://docs.influxdata.com/influxdb3/core/object-storage/
- **Supported Providers:**
  - [MinIO](#object-storage-minio)
  - AWS S3 (native support)
  - Azure Blob Storage (native support)
  - Google Cloud Storage (native support)

#### MinIO Configuration
- **Link:** https://docs.influxdata.com/influxdb3/core/object-storage/minio/

### Query System Data
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/query-system-data/

### Back Up and Restore
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/backup-restore/

### Performance Tuning
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/performance-tuning/

### Upgrade InfluxDB
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/upgrade/

### Use the InfluxDB MCP Server
- **Link:** https://docs.influxdata.com/influxdb3/core/admin/mcp-server/

---

## Reference

- **Main Link:** https://docs.influxdata.com/influxdb3/core/reference/

### Configuration Options
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/config-options/

### Command Line Interface (CLI)

#### Main CLI Reference
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/

#### CLI Commands - Create
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/create/
- **Subcommands:**
  - [database](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/create/database/)
  - [distinct_cache](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/create/distinct_cache/)
  - [last_cache](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/create/last_cache/)
  - [table](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/create/table/)
  - [token](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/create/token/)
    - [--admin flag](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/create/token/admin/)
  - [trigger](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/create/trigger/)

#### CLI Commands - Delete
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/delete/
- **Subcommands:**
  - [token](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/delete/token/)
  - [database](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/delete/database/)
  - [distinct_cache](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/delete/distinct_cache/)
  - [last_cache](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/delete/last_cache/)
  - [table](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/delete/table/)
  - [trigger](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/delete/trigger/)

#### CLI Commands - Disable/Enable
- **Disable:** https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/disable/
  - [trigger](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/disable/trigger/)
- **Enable:** https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/enable/
  - [trigger](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/enable/trigger/)

#### CLI Commands - Install
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/install/
- **Subcommands:**
  - [package](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/install/package/)

#### CLI Commands - Query/Write/Serve
- [query](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/query/)
- [write](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/write/)
- [serve](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/serve/)

#### CLI Commands - Show
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/show/
- **Subcommands:**
  - [plugins](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/show/plugins/)
  - [databases](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/show/databases/)
  - [system](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/show/system/)
    - [summary](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/show/system/summary/)
    - [table](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/show/system/table/)
    - [table-list](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/show/system/table-list/)
  - [tokens](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/show/tokens/)
  - [retention](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/show/retention/)

#### CLI Commands - Test
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/test/
- **Subcommands:**
  - [wal_plugin](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/test/wal_plugin/)
  - [schedule_plugin](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/test/schedule_plugin/)

#### CLI Commands - Update
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/update/
- **Subcommands:**
  - [database](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/update/database/)
  - [trigger](https://docs.influxdata.com/influxdb3/core/reference/cli/influxdb3/update/trigger/)

### Line Protocol
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/line-protocol/

### Processing Engine
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/processing-engine/

### SQL Reference

#### Main SQL Reference
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/

#### SQL Data Types
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/data-types/

#### SQL SELECT Statement
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/select/

#### SQL JOIN Clause
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/join/

#### SQL WHERE Clause
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/where/

#### SQL GROUP BY Clause
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/group-by/

#### SQL ORDER BY Clause
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/order-by/

#### SQL HAVING Clause
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/having/

#### SQL LIMIT Clause
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/limit/

#### SQL UNION Clause
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/union/

#### SQL EXPLAIN Command
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/explain/

#### SQL Information Schema
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/information-schema/

#### SQL Subqueries
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/subqueries/

#### SQL Operators
- **Main:** https://docs.influxdata.com/influxdb3/core/reference/sql/operators/
- **Types:**
  - [Arithmetic](https://docs.influxdata.com/influxdb3/core/reference/sql/operators/arithmetic/)
  - [Comparison](https://docs.influxdata.com/influxdb3/core/reference/sql/operators/comparison/)
  - [Logical](https://docs.influxdata.com/influxdb3/core/reference/sql/operators/logical/)
  - [Bitwise](https://docs.influxdata.com/influxdb3/core/reference/sql/operators/bitwise/)
  - [Other](https://docs.influxdata.com/influxdb3/core/reference/sql/operators/other/)

#### SQL Functions
- **Main:** https://docs.influxdata.com/influxdb3/core/reference/sql/functions/
- **Categories:**
  - [Aggregate](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/aggregate/)
  - [Selector](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/selector/)
  - [Time and date](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/time-and-date/)
  - [Conditional](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/conditional/)
  - [Math](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/math/)
  - [String](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/string/)
  - [Binary string](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/binary-string/)
  - [Array](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/array/)
  - [Map](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/map/)
  - [Struct](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/struct/)
  - [Regular expression](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/regular-expression/)
  - [Hashing](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/hashing/)
  - [Cache](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/cache/)
  - [Miscellaneous](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/misc/)
  - [Window](https://docs.influxdata.com/influxdb3/core/reference/sql/functions/window/)

#### SQL Table Value Constructor
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sql/table-value-constructor/

### InfluxQL Reference

#### Main InfluxQL Reference
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/

#### InfluxQL SELECT Statement
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/select/

#### InfluxQL WHERE Clause
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/where/

#### InfluxQL GROUP BY Clause
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/group-by/

#### InfluxQL ORDER BY Clause
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/order-by/

#### InfluxQL LIMIT and SLIMIT Clauses
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/limit-and-slimit/

#### InfluxQL OFFSET and SOFFSET Clauses
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/offset-and-soffset/

#### InfluxQL SHOW Statements
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/show/

#### InfluxQL Subqueries
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/subqueries/

#### InfluxQL Functions
- **Main:** https://docs.influxdata.com/influxdb3/core/reference/influxql/functions/
- **Categories:**
  - [Aggregates](https://docs.influxdata.com/influxdb3/core/reference/influxql/functions/aggregates/)
  - [Selectors](https://docs.influxdata.com/influxdb3/core/reference/influxql/functions/selectors/)
  - [Transformations](https://docs.influxdata.com/influxdb3/core/reference/influxql/functions/transformations/)
  - [Date and time](https://docs.influxdata.com/influxdb3/core/reference/influxql/functions/date-time/)
  - [Miscellaneous](https://docs.influxdata.com/influxdb3/core/reference/influxql/functions/misc/)

#### InfluxQL Time and Time Zones
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/time-and-timezone/

#### InfluxQL Regular Expressions
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/regular-expressions/

#### InfluxQL Quotation
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/quoting/

#### InfluxQL Math Operators
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/math-operators/

#### InfluxQL Internals
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/internals/

#### InfluxQL Feature Support
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/influxql/feature-support/

### HTTP API
- **Main:** https://docs.influxdata.com/influxdb3/core/reference/api/
- **InfluxDB 3 API:** https://docs.influxdata.com/influxdb3/core/api/v3/

### Client Libraries

#### Main Client Libraries
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/client-libraries/

#### Arrow Flight Clients
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/client-libraries/flight/
- **Supported Languages:**
  - [C# .NET](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/flight/csharp-flight/)
  - [Go](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/flight/go-flight/)
  - [Java Flight SQL](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/flight/java-flightsql/)
  - [Python](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/flight/python-flight/)
  - [Python Flight SQL](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/flight/python-flightsql-dbapi/)

#### v3 Client Libraries
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v3/
- **Supported Languages:**
  - [C# .NET](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v3/csharp/)
  - [Go](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v3/go/)
  - [Java](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v3/java/)
  - [JavaScript](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v3/javascript/)
  - [Python](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v3/python/)

#### v2 Client Libraries
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/
- **Supported Languages:**
  - [Arduino](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/arduino/)
  - [C#](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/csharp/)
  - [Dart](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/dart/)
  - [Go](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/go/)
  - [Java](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/java/)
  - [JavaScript](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/javascript/)
    - [Browsers and web clients](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/javascript/browser/)
    - [Node.js](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/javascript/nodejs/)
      - [Install](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/javascript/nodejs/install/)
      - [Write](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/javascript/nodejs/write/)
  - [Kotlin](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/kotlin/)
  - [PHP](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/php/)
  - [Python](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/python/)
  - [R](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/r/)
  - [Ruby](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/ruby/)
  - [Scala](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/scala/)
  - [Swift](https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v2/swift/)

#### v1 Client Libraries
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/client-libraries/v1/

### Core Internals
- **Main:** https://docs.influxdata.com/influxdb3/core/reference/internals/
- **Topics:**
  - [Data retention](https://docs.influxdata.com/influxdb3/core/reference/internals/data-retention/)
  - [Authentication and authorization](https://docs.influxdata.com/influxdb3/core/reference/internals/authentication/)
  - [Data durability](https://docs.influxdata.com/influxdb3/core/reference/internals/durability/)

### Naming Restrictions and Conventions
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/naming-restrictions/

### Usage Telemetry
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/telemetry/

### Glossary
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/glossary/

### Sample Data
- **Link:** https://docs.influxdata.com/influxdb3/core/reference/sample-data/

### Release Notes
- **Link:** https://docs.influxdata.com/influxdb3/core/release-notes/

---

## Additional Resources

### Community Support
- **InfluxDB Discord Server:** https://discord.gg/9zaNCW2PRT (Preferred)
- **InfluxDB Community Slack:** https://influxdata.com/slack
- **InfluxData Community:** https://community.influxdata.com/
- **InfluxDB Subreddit:** https://reddit.com/r/influxdb
- **InfluxData Support:** https://support.influxdata.com/ (For customers with contracts)

### Blog and Announcements
- **InfluxDB 3.7 Announcement:** https://www.influxdata.com/blog/influxdb-3-7/
- **InfluxDB 3 Explorer 1.5:** https://docs.influxdata.com/influxdb3/explorer/get-started/

### Related Products
- **InfluxDB 3 Enterprise:** https://docs.influxdata.com/influxdb3/enterprise/
- **InfluxDB Clustered:** https://docs.influxdata.com/influxdb3/clustered/
- **InfluxDB Cloud Serverless:** https://docs.influxdata.com/influxdb3/cloud-serverless/
- **InfluxDB Cloud Dedicated:** https://docs.influxdata.com/influxdb3/cloud-dedicated/
- **InfluxDB 3 Explorer (UI Tool):** https://docs.influxdata.com/influxdb3/explorer/
- **Telegraf:** https://docs.influxdata.com/telegraf/v1/
- **Flux Query Language:** https://docs.influxdata.com/flux/v0/

---

## Summary Statistics

- **Total Main Sections:** 10
- **Total Subsections:** 50+
- **CLI Commands Documented:** 25+
- **SQL Functions:** 14 categories
- **Client Libraries Supported:** 20+ languages
- **Official Plugins:** 11
- **Query Languages:** 2 (SQL and InfluxQL)
- **API Versions:** 2 (v1 and v3)
- **Documentation Links:** 200+

---

## Document Metadata

- **Source:** https://docs.influxdata.com/influxdb3/core/
- **Last Updated:** December 10, 2025
- **InfluxDB Version Covered:** 3.7
- **Document Format:** Markdown
- **Purpose:** Comprehensive index and reference guide for InfluxDB v.3 Core documentation

---

## How to Use This Document

This document serves as a complete index and reference for InfluxDB v.3 Core documentation. You can:

1. **Use Ctrl+F** to search for specific topics or keywords
2. **Navigate using Table of Contents** for organized browsing
3. **Click on links** to go directly to official InfluxDB documentation pages
4. **Use as a roadmap** for learning InfluxDB v.3 systematically
5. **Reference for selecting appropriate sections** based on your use case

---

**End of Document**
