# ETL Project 🔄

## Overview

<div align="center">
  <img src="https://www.databricks.com/sites/default/files/inline-images/etl-process-image.png" alt="ETL Process">
</div>

This ETL (Extract, Transform, Load) project processes order data from two sources, applies transformations, filters, and generates analytical summaries. The project is implemented in OCaml using functional programming principles with a clear separation between pure and impure functions.

## Table of Contents 📑

- [Requirements Checklist](#requirements-checklist-)
- [Installation](#installation-%EF%B8%8F)
- [Usage Examples](#usage-examples-)
- [Querying the SQLite Database](#querying-the-sqlite-database-)
- [Running Tests](#running-tests-)
- [Project Structure](#project-structure-)
- [External Libraries](#external-libraries-)
- [Architecture](#architecture-%EF%B8%8F)

## Requirements Checklist ✅

### Mandatory Requirements

- [x] 1. Project implemented in OCaml
- [x] 2. Data processing using map, reduce, and filter functions
- [x] 3. Functions for reading and writing CSV files (impure functions)
- [x] 4. Separation of pure and impure functions in the project structure
- [x] 5. Data loaded into a list of Records structure
- [x] 6. Helper functions used to load fields into Records
- [x] 7. Project report documenting implementation steps and AI usage

### Optional Requirements

- [x] 1. Reading input data from static files on the internet (via HTTP)
- [x] 2. Saving output data to a SQLite database
- [x] 3. Data processing using inner join operations (joining tables before transformation)
- [x] 4. Project organized using the Dune build system
- [x] 5. All functions documented using docstring format
- [x] 6. Additional output containing average revenue and taxes grouped by month and year
- [x] 7. Comprehensive test files for all pure functions

**All 7 optional requirements completed** ✓

## Installation 🛠️

### Prerequisites

- OCaml (version 4.13.0 or higher)
- OPAM (OCaml Package Manager)
- Dune (build system)

### Dependencies

This project relies on the following OCaml libraries:

- [csv](https://github.com/Chris00/ocaml-csv) - CSV parsing and formatting
- [ocurl](https://github.com/ygrek/ocurl) - HTTP requests
- [sqlite3](https://github.com/mmottl/sqlite3-ocaml) - SQLite database operations
- [ounit2](https://github.com/gildor478/ounit) - Unit testing framework

### Setup

1. Clone the repository:
   ```
   git clone <repository-url>
   ```
2. Reopen using Container

2. Install dependencies using OPAM:
   ```
   cd ETL
   opam install -y dune utop ocaml-lsp-server
   opam install . --deps-only --with-test
   ```

3. Build the project:
   ```
   eval $(opam env)
   dune build
   ```

## Usage Examples 📋

### Basic Usage

Process orders and order items from local files:

```bash
dune exec -- etl --input-orders data/order.csv --input-items data/order_item.csv --output data/order_summary.csv
```

### Reading Data from URLs

Process orders and order items from remote URLs:

```bash
dune exec -- etl --input-orders https://raw.githubusercontent.com/lorrancmlopes/ETL/refs/heads/main/ETL/data/order.csv --input-items https://raw.githubusercontent.com/lorrancmlopes/ETL/refs/heads/main/ETL/data/order_item.csv --output data/order_summary.csv
```

### Filtering by Status

Process only orders with "Complete" status:

```bash
dune exec -- etl --input-orders data/order.csv --input-items data/order_item.csv --output data/complete_orders.csv --status Complete
```

### Filtering by Origin

Process only orders with "P" (physical) origin:

```bash
dune exec -- etl --input-orders data/order.csv --input-items data/order_item.csv --output data/physical_orders.csv --origin P
```

### Combined Filtering

Process only orders with "Complete" status and "P" (physical) origin:

```bash
dune exec -- etl --input-orders data/order.csv --input-items data/order_item.csv --output data/complete_physical_orders.csv --status Complete --origin P
```

### Generating Period Summaries

Generate period-based (year/month) summary statistics:

```bash
dune exec -- etl --input-orders data/order.csv --input-items data/order_item.csv --output data/order_summary.csv --period-output data/period_summary.csv
```

### Saving to SQLite Database

Save results to a SQLite database:

```bash
dune exec -- etl --input-orders data/order.csv --input-items data/order_item.csv --output data/order_summary.csv --db-file data/order_summary.db
```

### All Features Combined

Use all features together:

```bash
dune exec -- etl --input-orders https://raw.githubusercontent.com/lorrancmlopes/ETL/refs/heads/main/ETL/data/order.csv --input-items https://raw.githubusercontent.com/lorrancmlopes/ETL/refs/heads/main/ETL/data/order_item.csv --output data/order_summary.csv --period-output data/period_summary.csv --status Complete --origin O --db-file data/order_summary.db
```

## Querying the SQLite Database 🔍

After processing data and saving it to a SQLite database, you can query it using the `sqlite3` command-line tool:

```bash
# Open the database
sqlite3 data/order_summary.db

# List all tables
.tables

# Show table schema
.schema order_summaries

# Query all order summaries
SELECT * FROM order_summaries;

# Query order summaries with total amount greater than 2000
SELECT * FROM order_summaries WHERE total_amount > 2000;

# Calculate average total_amount
SELECT AVG(total_amount) FROM order_summaries;

# Exit SQLite
.quit
```

## Running Tests 🧪

Run all tests:

```bash
dune test
```

Run specific test files:

```bash
dune exec -- _build/default/test/test_helper.exe
dune exec -- _build/default/test/test_filter.exe
dune exec -- _build/default/test/test_transform.exe
dune exec -- _build/default/test/test_etl.exe
```

## Project Structure 📁

```
ETL/
├── etl/
│   ├── bin/           # Executable entry points (impure functions)
│   │   ├── main.ml    # CLI entry point
│   │   └── dune       # Build configuration
│   │
│   ├── lib/           # Core library modules
│   │   ├── types.ml   # Data type definitions
│   │   ├── helper.ml  # Conversion utilities (pure)
│   │   ├── filter.ml  # Filtering functions (pure)
│   │   ├── transform.ml # Transformation functions (pure)
│   │   ├── reader.ml  # File and URL reading (impure)
│   │   ├── writer.ml  # File output (impure)
│   │   ├── db.ml      # Database operations (impure)
│   │   ├── etl.ml     # Main orchestration module
│   │   ├── etl.mli    # Interface definition
│   │   └── dune       # Build configuration
│   │
│   ├── test/          # Test files
│   │   ├── test_etl.ml      # Main test file
│   │   ├── test_helper.ml   # Helper module tests
│   │   ├── test_filter.ml   # Filter module tests
│   │   ├── test_transform.ml # Transform module tests
│   │   └── dune             # Test configuration
│   │
│   ├── data/          # Sample data files
│   │   ├── order.csv         # Sample order data
│   │   ├── order_item.csv    # Sample order item data
│   │   └── order_summary.db  # SQLite database (created by the program)
│   │
│   ├── dune-project   # Project configuration
│   └── etl.opam       # Package configuration
```

## External Libraries 📚

The project uses the following external libraries:

- **[csv](https://github.com/Chris00/ocaml-csv)** - For reading and writing CSV files
  - [OPAM Package](https://opam.ocaml.org/packages/csv/)
  - [Documentation](https://ocaml.org/p/csv/latest/doc/Csv/index.html)

- **[ocurl](https://github.com/ygrek/ocurl)** - For HTTP requests
  - [OPAM Package](https://opam.ocaml.org/packages/ocurl/)
  - [Documentation](https://ocaml.org/p/ocurl/latest/doc/Curl/index.html)

- **[sqlite3](https://github.com/mmottl/sqlite3-ocaml)** - For SQLite database operations
  - [OPAM Package](https://opam.ocaml.org/packages/sqlite3/)
  - [Documentation](https://ocaml.org/p/sqlite3/latest/doc/Sqlite3/index.html)

- **[ounit2](https://github.com/gildor478/ounit)** - For unit testing
  - [OPAM Package](https://opam.ocaml.org/packages/ounit2/)
  - [Documentation](https://ocaml.org/p/ounit2/latest/doc/index.html)

## Architecture 🏗️

The project follows a functional approach with a clear separation of concerns:

1. **Types Module**: Defines the core data structures
2. **Helper Module**: Provides pure functions for data conversion
3. **Filter Module**: Contains pure functions for filtering data
4. **Transform Module**: Implements pure functions for data transformation
5. **Reader Module**: Handles impure I/O operations for input
6. **Writer Module**: Manages impure I/O operations for output
7. **DB Module**: Provides impure functions for database operations
8. **ETL Module**: Orchestrates the entire ETL process

The separation between pure and impure functions improves testability and maintainability.

<div align="center">
    <br>
    @2025, Insper. 10th Semester, Computer Engineering.<br>
    Functional Programming Discipline
</div>
