# FoodPal: Distributed Recipe Management Suite

## Overview
This system was developed as a core project within the **Computer Science & Engineering** curriculum at **Delft University of Technology (TU Delft)**.

Developed by **CSEP Team 36** during the **2025–2026** cycle, its core objective is to provide a **scalable, distributed organizer** for recipe and ingredient management.

## Project Context

*   **Academic Institution:** Delft University of Technology (TU Delft)
*   **Project Group:** CSEP Team 36
*   **Development Cycle:** 2025–2026
*   **Core Objective:** Engineering a scalable, distributed organizer for recipe and ingredient management

## System Architecture
The application is built on a client–server model that prioritizes a client-agnostic backend. This design keeps global data centralized, while user-specific configuration is handled on the client side.

*   **Stateless Backend:** The server manages global CRUD operations (Create, Read, Update, Delete) for recipes without storing session-specific client state.
*   **Automated Data Transformation:** Integrated **Jackson** for JSON-to-object mapping, enabling seamless RESTful communication.
*   **Distributed Synchronization:** **Spring Boot** + **JavaFX** architecture supports real-time data sharing across multiple concurrent clients.
*   **Local Persistence:** Client-specific data (favorite recipes, server configuration, etc.) is stored in a local persistent JSON format.
*   **Dynamic Mutation Logic:** Deep-copy cloning allows users to fork existing recipes without affecting the integrity of the central data store.

## Technical Specifications

*   **Languages:** Java (Advanced), SQL (PostgreSQL)
*   **Frameworks:** Spring Boot (Backend), JavaFX (Frontend)
*   **Build System:** Maven (multi-module: client, server, commons)
*   **Data Interchange:** RESTful APIs using JSON serialization
*   **Code Quality:** Enforced via Checkstyle to maintain strict complexity and documentation standards

## Execution Instructions
The project uses the Maven Wrapper to ensure a consistent execution environment.

**Initialize Server:**
mvn -pl server -am spring-boot:run
**Initialize Client:**
mvn -pl client -am javafx:run
```bash
mvn -pl server -am spring-boot:run
