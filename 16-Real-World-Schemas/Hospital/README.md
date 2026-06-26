# 🏥 Hospital Management Database Schema

## Overview
This database schema models a clinical and administrative management system for a hospital or clinic. It tracks departments, staffing (doctors), patients, hospital rooms, appointment scheduling (with double-booking protection), clinical medical records, pharmacy prescriptions, and billing statements with automated net amount calculation.

## Schema Architecture

```mermaid
erDiagram
    DEPARTMENTS ||--o{ DOCTORS : "employs"
    DEPARTMENTS ||--o{ ROOMS : "allocates"
    PATIENTS ||--o{ APPOINTMENTS : "schedules"
    PATIENTS ||--o{ MEDICAL_RECORDS : "has"
    PATIENTS ||--o{ PRESCRIPTIONS : "receives"
    PATIENTS ||--o{ BILLING : "billed"
    DOCTORS ||--o{ APPOINTMENTS : "attends"
    DOCTORS ||--o{ MEDICAL_RECORDS : "documents"
    DOCTORS ||--o{ PRESCRIPTIONS : "prescribes"
    ROOMS ||--o{ BILLING : "accrues charge"
    APPOINTMENTS ||--o? MEDICAL_RECORDS : "leads to"
    APPOINTMENTS ||--o? BILLING : "generates"
    MEDICAL_RECORDS ||--o{ PRESCRIPTIONS : "contains"
```

## Table Descriptions

### 1. `departments`
Hospital departments (e.g., Cardiology, Pediatrics). Stores structural information like floor numbers and internal phone extensions.

### 2. `doctors`
Physicians and medical specialists. Each doctor belongs to a department and has their license number tracked. A unique index `uq_doctor_slot` prevents double-booking.

### 3. `patients`
Detailed demographic, contact, insurance, and medical group (blood type, gender) metadata for registered patients.

### 4. `rooms`
Hospital rooms (ICU, Private, General, etc.) located in specific departments. Tracks daily room rates and current occupancy status.

### 5. `appointments`
Details patient visits. A check constraint prevents invalid time ranges. A partial unique index (`doctor_id, appointment_date, start_time`) ensures doctors aren't double-booked unless the previous appointment was cancelled or is a no-show.

### 6. `medical_records`
Clinical documentation containing symptoms, diagnoses, treatments, and clinical notes compiled during patient appointments.

### 7. `prescriptions`
Tracks specific medications, dosages, frequency, and instructions issued to a patient during their doctor visit.

### 8. `billing`
Financial statements. Computes `net_amount` dynamically: `total_amount - discount + tax`. Features a partial index on due dates for tracking unpaid/overdue bills.

---

## Sample Queries

### 1. Retrieve a Patient's Complete Medical and Prescription History
Combines medical records with their corresponding doctor and any prescribed medications.
```sql
SELECT 
    mr.record_date,
    mr.diagnosis,
    mr.treatment,
    CONCAT('Dr. ', d.first_name, ' ', d.last_name) AS physician,
    p.medication_name,
    p.dosage,
    p.frequency,
    p.duration_days
FROM medical_records mr
JOIN doctors d ON mr.doctor_id = d.doctor_id
LEFT JOIN prescriptions p ON mr.record_id = p.record_id
WHERE mr.patient_id = 105
ORDER BY mr.record_date DESC;
```

### 2. Find Available Rooms in the Cardiology Department
Locates vacant beds within specific departments of the hospital.
```sql
SELECT 
    r.room_number,
    r.type AS room_type,
    r.bed_count,
    r.daily_rate,
    r.floor_number
FROM rooms r
JOIN departments d ON r.department_id = d.department_id
WHERE d.name = 'Cardiology' 
  AND r.status = 'available'
ORDER BY r.daily_rate ASC;
```

### 3. Retrieve Doctor Daily Appointment Schedules
List scheduled, non-cancelled appointments for a physician on a given date.
```sql
SELECT 
    a.start_time,
    a.end_time,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.phone AS patient_phone,
    a.status,
    a.reason
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
WHERE a.doctor_id = 2 
  AND a.appointment_date = '2026-06-26'
  AND a.status NOT IN ('cancelled', 'no_show')
ORDER BY a.start_time;
```

### 4. Patient Outstanding Balance & Overdue Bills Report
Finds unpaid accounts that have passed their due dates.
```sql
SELECT 
    b.bill_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    b.net_amount AS outstanding_balance,
    b.due_date,
    CURRENT_DATE - b.due_date AS days_overdue
FROM billing b
JOIN patients p ON b.patient_id = p.patient_id
WHERE b.status IN ('pending', 'partially_paid') 
  AND b.due_date < CURRENT_DATE
ORDER BY days_overdue DESC;
```
