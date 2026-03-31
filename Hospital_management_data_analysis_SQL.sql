-- =====================================================
-- HOSPITAL DATA ANALYSIS PROJECT
-- SQL ANALYSIS
-- =====================================================

--                                                     DATABASE SETUP

CREATE DATABASE Hospital_management;
USE Hospital_management;
--    ==========================================================================================================
--                                          SECTION 1 : DATA EXPLORATION
--    ==========================================================================================================

-- Provide the second patient row
SELECT *
FROM patients
LIMIT 1 offset 1;

-- how many patients recently registered in the last 30 days?

SELECT * FROM patients
WHERE registration_date >= (SELECT max(registration_date) - interval 30 day from patients)
ORDER BY registration_date desc;

-- Insight:
-- Only one patient was registered in the last 30 days relative to the most
-- recent registration date in the dataset. This may indicate a decline in
-- patient inflow during that period and could require investigation into
-- hospital outreach or service demand.

-- how many doctors are there in the hospital?

SELECT COUNT(*) FROM DOCTORS;

-- What are distinct specialisation in the hospital

SELECT DISTINCT SPECIALIZATION FROM DOCTORS;

-- insight - The hospital supports multiple medical specializations, ensuring a wide range of healthcare services for patients.

--             ==========================================================================================================
--                                                  SECTION 2 : DOCTOR ANALYSIS
--             ==========================================================================================================

-- SORT THE DOCTORS BASED ON EXPERIENCE AND PROVIDE FIRST NAME AND LAST NAME TOGETHER.

SELECT CONCAT(first_name,' ', last_name) as doctor_name, specialization, years_experience
FROM doctors
ORDER BY years_experience desc;

-- Insight:
-- Doctors with higher years of experience may handle more complex cases and critical treatments.

-- find the doctor name ending with 'is' based on first name

SELECT first_name
from doctors
WHERE first_name like '%is';

--                 ==========================================================================================================
--                                                    SECTION 3 : APPOINTMENT ANALYSIS
--                 ==========================================================================================================

-- what is the appointment status distribution

SELECT status, count(*)
from appointments
group by status;

-- Insight :
-- A significant number of appointments are No-Show or Cancelled, which indicates inefficiencies in
-- scheduling. The hospital could introduce appointment reminders or confirmation systems to reduce missed
-- appointments and improve resource utilization.

-- provide me the status types whose count is more than 50

SELECT status, count(*)
from appointments
group by status
HAVING count(*) > 50;

-- find all the appointments in the last 7 days

SELECT * FROM APPOINTMENTS
WHERE appointment_date >= (SELECT max(appointment_date) - interval 7 day from appointments)
order by appointment_date desc;

-- Insight :
-- Monitoring recent appointments helps hospital management track current patient demand trends.

-- Appointment Status Distribution

SELECT status, COUNT(*) AS total, ROUND(COUNT(*)*100/(SELECT COUNT(*) FROM appointments),2) AS percentage
FROM appointments
GROUP BY status;

-- Insight :
-- The distribution of appointment statuses highlights the proportion of completed, cancelled, and pending appointments. 
-- A high percentage of cancelled or no-show appointments may indicate inefficiencies in scheduling, 
-- suggesting the need for appointment reminders or improved booking systems.

-- Daily Appointment Trend

SELECT appointment_date, COUNT(*) AS total_appointments
FROM appointments
GROUP BY appointment_date
ORDER BY appointment_date;

-- Insight :
-- The number of appointments varies across different days, indicating fluctuations in patient demand. 
-- Identifying days with higher appointment volumes can help hospital management optimize doctor scheduling 
-- and resource allocation to ensure efficient service delivery.

-- are there appointment statuses that indicate patients disengagement risk?

SELECT status, count(*) as appointment_count
FROM appointments
group by status;

-- Insight:
-- A higher number of cancelled and no-show appointments compared to completed ones
-- indicates potential patient disengagement, which may require improved scheduling
-- systems or patient follow-up mechanisms.

-- monthly appointment trend

SELECT year(appointment_date) as year,
	   month(appointment_date) as month,
       count(*) as appointment_count
from appointments
group by year, month
order by year, month;

-- appointments by day of week

SELECT dayname(appointment_date) as day_of_week,
	count(*) as appointment_count
from appointments 
group by day_of_week;

-- appointment sequence per patient

SELECT patient_id, appointment_id, appointment_date,
       row_number() over(partition by patient_id order by appointment_date) as visit_number
from appointments;

--               ==========================================================================================================
--                                                SECTION 4: TREATMENT ANALYSIS
--               ==========================================================================================================

-- most common treatment

SELECT treatment_type, COUNT(*) AS treatment_count
FROM treatments
GROUP BY treatment_type
ORDER BY treatment_count DESC;
-- Insight :
-- Diagnostic and therapy procedures dominate the treatment distribution, 
-- indicating the hospital primarily handles diagnostic imaging and chronic disease management services.

-- find minimum cost, maximum cost and average cost round to 1 decimal place

SELECT min(cost) as min_cost, max(cost) as max_cost, round(avg(cost),1) as avg_cost
from treatments;

-- Insight :
-- Treatment costs vary significantly, reflecting differences between basic diagnostic procedures and advanced treatments. 
-- Monitoring cost distribution helps the hospital maintain transparent pricing and cost control.


--                 ==========================================================================================================
--                                                   Section 5 — Billing Analysis
--                 ==========================================================================================================

-- PAYMENT STATUS DISTRIBUTION

SELECT payment_status, COUNT(*) AS bill_count
FROM billing
GROUP BY payment_status;
-- Insight :
-- Analyzing payment status helps monitor billing efficiency and pending payments, which directly impact hospital cash flow.

--                 ==========================================================================================================
--                                                    Section 6 — Patient Demographics
--                 ==========================================================================================================

-- how many patients are registered from each address?

SELECT address, count(*) as patient_count
from patients
group by address
order by patient_count desc;    

-- Insight :
-- Certain locations contribute more patients, indicating primary service areas of the hospital.

-- VIP Patients Ranking Based on Total Spending

WITH patient_spending AS (
SELECT p.patient_id, CONCAT(p.first_name,' ',p.last_name) AS patient_name, SUM(b.amount) AS total_spent
FROM patients p
JOIN billing b
ON p.patient_id = b.patient_id
WHERE b.payment_status = 'paid'
GROUP BY p.patient_id, patient_name
)

SELECT *,
RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM patient_spending;

-- Insight :
-- A small number of patients often contribute a large share of hospital revenue, 
-- highlighting the importance of identifying and managing high-value patients effectively.

-- what is the age distribution of patients

SELECT patient_id, first_name, gender, TIMESTAMPDIFF(YEAR, date_of_birth, curdate()) as age
from patients;

-- Insight :
-- Understanding patient age distribution helps hospitals tailor healthcare services for different age groups.


-- Age group segmentation
-- 18-35
-- 36-55
-- 56+

-- age_group, patient_count

SELECT 
case
    when TIMESTAMPDIFF(YEAR, DATE_OF_BIRTH, CURDATE()) < 18 THEN 'Under 18'
    when TIMESTAMPDIFF(YEAR, DATE_OF_BIRTH, CURDATE()) BETWEEN 18 AND 35 THEN 'Adults'
    when TIMESTAMPDIFF(YEAR, DATE_OF_BIRTH, CURDATE()) BETWEEN 36 AND 55 THEN 'Matured'
	else 'Seniors'
END AS age_group,
count(*) as patient_count
from patients
group by age_group
order by patient_count desc;

-- Insight : 
-- Adults and middle-aged patients often dominate hospital visits due to higher healthcare needs during working years.

-- rank patients by total spending

SELECT p.patient_id, 
p.first_name as patient_name, 
sum(b.amount) as total_spent, 
rank() over (order by sum(b.amount) desc) as spending_rank
from patients p join billing b
on p.patient_id = b.patient_id
where b.payment_status = 'paid'
group by patient_id, patient_name;

-- what is gap between patient visits?

SELECT patient_id, appointment_id, appointment_date,
DATEDIFF(
    appointment_date,
    LAG(appointment_date) OVER (PARTITION BY patient_id ORDER BY appointment_date)
) AS days_between_visits
FROM appointments;
-- Insight:
-- The gap between patient visits helps identify patient follow-up patterns.
-- Longer gaps may indicate irregular treatment or patient drop-off,
-- while shorter gaps suggest ongoing treatment or chronic condition management.

--                       ==========================================================================================================
--                                                        Section 7 — Hospital Operations
--                       ==========================================================================================================

-- which email domains are commonly used by patients

SELECT SUBSTRING_INDEX(email,'@',-1) AS email_domain, COUNT(*) AS patient_count
FROM patients
GROUP BY email_domain
ORDER BY patient_count DESC;

-- which month has higher patient registration

SELECT DATE_FORMAT(registration_date,'%Y-%m') AS registration_month, COUNT(*) AS patient_count
FROM patients
GROUP BY registration_month
ORDER BY registration_month;
-- Insight:
-- Patient registrations vary across months, indicating seasonal trends
-- in healthcare demand which can help in resource planning.

-- which medical specialisation are most in demand based on appointment value?

SELECT d.specialization, count(a.appointment_id) as total_appointments
from appointments a join doctors d
on a.doctor_id = d.doctor_id
group by d.specialization;

-- Insight : 
-- Some medical specializations receive higher appointment volumes, 
-- which may lead to doctor workload imbalance. Hospital management may need to hire more specialists or redistribute patient load.

-- are critical specialisation supported by senior experienced doctor or junior doctor?

SELECT specialization, count(*) as total_doctors,
sum(case when years_experience >= 15 THEN 1 else 0 END) AS senior_doctors,
sum(case when years_experience < 15 THEN 1 else 0 END) AS junior_doctors
from doctors
group by specialization;

-- Insight : 
-- Critical specializations supported by experienced doctors ensure better patient care and expertise availability.

-- make a table/master data>> appointments with patient details and doctor specialization

SELECT a.appointment_id, 
concat(p.first_name, ' ', p.last_name) as patient_name,
concat(d.first_name, ' ', d.last_name) as doctor_name,
d.specialization,
a.appointment_date,
a.appointment_time,
a.reason_for_visit,
a.status
FROM appointments a
join patients p
on a.patient_id = p.patient_id
join doctors d
on a.doctor_id = d.doctor_id
order by a.appointment_date desc limit 5;


-- which doctors are over loaded and which have available capacity based on appointment value?

SELECT CONCAT(d.first_name,' ',d.last_name) AS doctor_name, d.specialization, COUNT(a.appointment_id) AS total_appointments,
CASE
    WHEN COUNT(a.appointment_id) > 100 THEN 'Overloaded'
    WHEN COUNT(a.appointment_id) BETWEEN 50 AND 100 THEN 'Moderate'
    ELSE 'Available'
END AS workload_status
FROM doctors d
LEFT JOIN appointments a
ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, doctor_name, d.specialization
ORDER BY total_appointments DESC;

-- Insight : 
-- Certain doctors handle significantly more appointments than others, 
-- suggesting uneven workload distribution. 
-- Optimizing the appointment scheduling system could improve efficiency and reduce doctor burnout.

-- build a big master data where we can see the entire journey of patients

SELECT a.appointment_id, 
concat(p.first_name, ' ', p.last_name) as patient_name,
a.appointment_date,
a.appointment_time,
a.reason_for_visit,
a.status,
t.cost as treatment_cost,
b.amount as billed_amount,
b.payment_status
from patients p
join appointments a
on p.patient_id = a.patient_id
left join treatments t
on a.appointment_id = t.appointment_id
left join billing b
on t.treatment_id = b.treatment_id
order by p.patient_id, a.appointment_date;

-- Top 5 Doctors by Appointment Volume

SELECT d.first_name as doctor_name, d.specialization, count(a.appointment_id) as total_appointments
FROM doctors d join appointments a
on d.doctor_id = a.doctor_id
group by d.doctor_id, doctor_name, d.specialization
order by total_appointments desc
limit 5;

--                           ==========================================================================================================
--                                                             Section 8 — Revenue Analysis
--                           ==========================================================================================================

-- what is total revenue generated by company

select sum(amount) as total_revenue
from billing
where payment_status = 'paid';

-- Insight : 
-- Total revenue reflects the financial health of the hospital operations.

-- which patients contributes the most revenue

SELECT 
      p.patient_id,
      concat(p.first_name, ' ', last_name) as patient_name,
      sum(b.amount) as total_spent
FROM patients p
join billing b
on p.patient_id = b.patient_id
where payment_status = 'paid'
GROUP BY p.patient_id, patient_name
order by total_spent desc
limit 10;

-- Insight : 
-- A small number of patients contribute a large portion of total hospital revenue, 
-- which is typical in healthcare systems where chronic or specialized treatments require repeated visits.

-- Revenue by Specialization

SELECT d.specialization, SUM(b.amount) AS total_revenue
FROM doctors d
JOIN appointments a
ON d.doctor_id = a.doctor_id
JOIN treatments t
ON a.appointment_id = t.appointment_id
JOIN billing b
ON t.treatment_id = b.treatment_id
WHERE b.payment_status = 'paid'
GROUP BY d.specialization
ORDER BY total_revenue DESC;

-- Insight : 
-- Certain medical specializations generate significantly higher revenue compared to others. 
-- This suggests that these specialties have either higher patient demand or higher treatment costs, 
-- making them key contributors to the hospital's overall revenue.

-- outlier detection
-- are there treatment with unusually high cost that requires review

select treatment_id,
treatment_type, 
cost
from treatments
where cost > (select avg(cost) + 2 *stddev(cost) from treatments);

-- Insight : 
-- Extremely high-cost treatments may represent specialized procedures or anomalies requiring review.

-- select treatment by frequency

select treatment_type,
count(*) as treatment_count,
rank() over (order by count(*) desc) as frequency_rank
from treatments 
group by treatment_type;


--                                ==========================================================================================================
--                                                                 FINAL BUSINESS INSIGHTS
--                                ==========================================================================================================

-- 1. Appointment cancellations and no-shows indicate inefficiencies in scheduling.
-- 2. Certain specializations drive the majority of hospital revenue.
-- 3. A small group of patients contributes significantly to total revenue.
-- 4. Doctor workload is unevenly distributed across the hospital.
-- 5. Treatment costs vary widely, with some high-cost outliers.
-- 6. Patient inflow shows fluctuations and potential decline in recent periods.


