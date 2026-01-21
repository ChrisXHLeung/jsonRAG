# jsonRAG: Logic-Driven Self-Healing Infrastructure

This project demonstrates a closed-loop, self-healing infrastructure architecture. It leverages **Infrastructure as Code (IaC)**, **Decoupled Authorization**, and **Real-time Monitoring** to automatically remediate security breaches or policy violations by rebuilding compromised computing nodes.

## 🧠 System Logic & Architecture

The system is designed around the principle of **"Recovery over Investigation."** Instead of manually patching a compromised server, the system treats infrastructure as immutable and recreates it from a known "gold" state.

![](https://raw.githubusercontent.com/ChrisXHLeung/jsonRAG/79a63ef6248442dab21c878a612f98d7b73b2765/Resilience/proxmox_self_healing.svg)

### 1. The Controller (API VM)

The **API VM** acts as the Control Plane. It sits outside the production worker cluster and manages the state of the entire environment using **Terraform**. It hosts a specialized `webhookAPI` that translates monitoring alerts into infrastructure actions.

### 2. High Availability Entrance

Traffic enters via a Virtual IP (VIP) managed by **Keepalived** across two **Nginx** nodes. This ensures that even if one load balancer fails, the path to the computing nodes remains open.

### 3. Stateless Computing Layer (Worker Nodes)

* **Worker Nodes**: These VMs perform the actual data processing (Computing).
* **Data Persistence**: All business data is offloaded to **Object Storage**. This decoupling is critical: it allows the Worker Nodes to be destroyed and recreated at any time without data loss.

### 4. The Security Feedback Loop

The "Self-Healing" mechanism follows four distinct stages:

* **Audit**: Every request within the computing nodes is authorized by **Cerbos**. Cerbos generates fine-grained audit logs of who attempted what action and whether it was allowed.
* **Detection**: **Zabbix** ingests these Cerbos audit trails. It looks for specific patterns, such as "Multiple Denied Access Attempts" or "Unauthorized System Change."
* **Trigger**: Upon detecting a violation, Zabbix sends an HTTP POST request to the `webhookAPI` on the **API VM**, identifying exactly which Worker Node is "tainted."
* **Remediation**: The `webhookAPI` triggers a Terraform execution:
1. It marks the specific Worker Node as tainted (`terraform taint` or `-replace`).
2. It executes a new plan to destroy the compromised VM.
3. It provisions a fresh, clean VM from the original template on **Proxmox VE**.



---

## 🛠 Logic Flow Diagram

![](https://raw.githubusercontent.com/ChrisXHLeung/jsonRAG/79a63ef6248442dab21c878a612f98d7b73b2765/Resilience/automated_worker_recovery.svg)

## 🎯 Key Design Benefits

* **Immutable Infrastructure**: Eliminates "configuration drift" by replacing VMs instead of fixing them.
* **Security Enforcement**: Moves security from a passive "logging" role to an active "enforcement" role.
* **Zero-Downtime Recovery**: Because there are multiple worker nodes and a load balancer, the system remains available while the API VM replaces a single faulty node.