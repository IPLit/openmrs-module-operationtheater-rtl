DELETE FROM global_property WHERE property = 'bahmni.sqlGet.pastSurgeries';
SELECT uuid() INTO @uuid;

INSERT INTO global_property (`property`, `property_value`, `description`, `uuid`)
VALUES ('bahmni.sqlGet.pastSurgeries',
 'SELECT sd.DASHBOARD_START_TIME_OF_SURGERY, sd.DASHBOARD_START_DATE_OF_SURGERY, sd.DASHBOARD_ACTUAL_START_DATE_OF_SURGERY, sd.DASHBOARD_ACTUAL_START_TIME_OF_SURGERY, ed.timeInHrs, ed.timeInMins, ed.cleaningTime, sd.status, sd.Location, sd.Surgeon from
   (SELECT
      DATE_FORMAT(sb.start_datetime, "%d/%m/%Y") AS `DASHBOARD_START_DATE_OF_SURGERY`,
      DATE_FORMAT(sb.start_datetime, "%l:%i %p") AS `DASHBOARD_START_TIME_OF_SURGERY`,
      DATE_FORMAT(sa.actual_start_datetime, "%d/%m/%Y") AS `DASHBOARD_ACTUAL_START_DATE_OF_SURGERY`,
      DATE_FORMAT(sa.actual_start_datetime, "%l:%i %p") AS `DASHBOARD_ACTUAL_START_TIME_OF_SURGERY`,
      l.name                                     AS Location,
      sa.surgical_appointment_id                 AS app_id,
      providerNames.provider_name                AS `Surgeon`,
      sa.status                                    AS Status
    FROM surgical_block sb
      INNER JOIN surgical_appointment sa ON sb.surgical_block_id = sa.surgical_block_id
                                            AND sb.voided IS FALSE
                                            AND sa.voided IS FALSE

      INNER JOIN person p ON p.person_id = sa.patient_id AND p.voided IS FALSE
      INNER JOIN person_name pn ON pn.person_id = sa.patient_id
                                   AND pn.voided IS FALSE
      INNER JOIN location l ON sb.location_id = l.location_id AND l.retired IS FALSE
      INNER JOIN (
                   SELECT
                     p2.provider_id,
                     pn2.person_id,
                     CONCAT(pn2.given_name,"", pn2.family_name) AS provider_name
                   FROM provider p2
                     INNER JOIN person_name pn2 ON pn2.person_id = p2.person_id AND
                                                   p2.retired IS FALSE AND pn2.voided IS FALSE
                 ) providerNames ON providerNames.provider_id = sb.primary_provider_id
    WHERE p.uuid = ${patientUuid} AND
          sb.start_datetime < CURDATE())  as sd,

  (SELECT  t2.surgical_appointment_id as `app_id`, t2.value as `cleaningTime`, t22.value as `timeInHrs`, t222.value as `timeInMins`
    FROM surgical_appointment_attribute_type t1, surgical_appointment_attribute t2, surgical_appointment_attribute t22, surgical_appointment_attribute_type t11, surgical_appointment_attribute t222, surgical_appointment_attribute_type t111
    WHERE t1.surgical_appointment_attribute_type_id = t2.surgical_appointment_attribute_type_id
    AND t1.name = "cleaningTime"
    AND t11.surgical_appointment_attribute_type_id = t22.surgical_appointment_attribute_type_id
    AND t11.name="estTimeHours"
    AND t111.surgical_appointment_attribute_type_id = t222.surgical_appointment_attribute_type_id
    AND t111.name="estTimeMinutes"
    AND t2.surgical_appointment_id= t22.surgical_appointment_id  AND t2.surgical_appointment_id =  t222.surgical_appointment_id ) as ed  where sd.app_id = ed.app_id
  ORDER BY sd.DASHBOARD_START_DATE_OF_SURGERY DESC'
   ,'Past surgeries for patient',@uuid);