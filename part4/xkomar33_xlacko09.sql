/*
=================================================================
                    IDS Projekt - SQL
Popis:  School Database Systems project, SQL for Oracle 12c 
Autoři: Jakub Komárek   (xkomar33)
        Lacko Dávid     (xlacko09)

=================================================================
*/
BEGIN
FOR rec IN (SELECT table_name from user_tables)
    LOOP
        DBMS_OUTPUT.PUT_LINE('Removing: ' || rec.TABLE_NAME);
        EXECUTE IMMEDIATE 'DROP TABLE "' || rec.TABLE_NAME || '" CASCADE CONSTRAINTS';
    END LOOP;
END;
/
CREATE TABLE person (
    birthNum VARCHAR2(10) PRIMARY KEY,

    firstName VARCHAR2(32) not NULL,
    midName VARCHAR2(32),
    lastName VARCHAR2(32),
    email VARCHAR2(32) not NULL,
    phoneNum VARCHAR2(15) not NULL,
    city VARCHAR2(32) not NULL,
    psc VARCHAR2(5) not NULL,
    street VARCHAR2(32) not NULL,
    streetNum VARCHAR2(10) not NULL,

    CHECK (regexp_like(birthNum,'^[0-9]{9,10}$')),
    CHECK (mod( CAST(birthNum as INT),11)=0),
    CHECK (SUBSTR(birthNum, 7,3)='000' or LENGTH(birthNum)=10),
    CHECK (to_date(SUBSTR(birthNum, 5,2) ||
        (case when CAST(SUBSTR(birthNum, 3,1) as int) >= 5 then
            CAST(SUBSTR(birthNum, 3,1) as int)-5
            else CAST(SUBSTR(birthNum, 3,1) as int) end) ||
        SUBSTR(birthNum, 4,1) ||
        (case when CAST(SUBSTR(birthNum, 1, 2) as int) > 53 then
            (case when LENGTH(birthNum)=9 then '18' else '19' end) || SUBSTR(birthNum, 1,2)
                else (case when LENGTH(birthNum)=9 then '19' else '20' end) || SUBSTR(birthNum, 1,2) end),'ddmmyyyy') is not null),
    CHECK (regexp_like(phoneNum,'^\+?[0-9|-]*$')),
    CHECK (regexp_like(email,'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')),
    CHECK (regexp_like(psc,'^[0-9]{5}$'))
);
CREATE TABLE "Client" (
    birthNum VARCHAR2(10) NOT NULL PRIMARY KEY REFERENCES person
);
CREATE TABLE department(
    id NUMBER GENERATED  by default on null as IDENTITY PRIMARY KEY,

    nameD VARCHAR2(32) not NULL,
    descriptionD VARCHAR2(64),
    room NUMBER(8),

    CHECK (room>=0)
);
CREATE TABLE worker (
    birthNum VARCHAR2(10) PRIMARY KEY REFERENCES person,
    workingIn INT REFERENCES DEPARTMENT,
    leads INT REFERENCES DEPARTMENT,

    specialization VARCHAR2(32),
    title VARCHAR2(10),
    wage NUMBER(8,2) DEFAULT 0 NOT NULL,

    CHECK (wage>=0)
);
CREATE TABLE "ORDER" (
    id NUMBER GENERATED  by default on null as IDENTITY PRIMARY KEY,
    clientBN VARCHAR2(10) NOT NULL REFERENCES "Client",
    workerBN VARCHAR2(10) NOT NULL REFERENCES worker,

    finalPrice int DEFAULT 0 ,
    deadLine DATE,
    state VARCHAR2(32) DEFAULT 'sended',
    dateOfCreation DATE default sysdate not null
);
CREATE TABLE requirement_counters(
    id NUMBER REFERENCES "ORDER" ON DELETE CASCADE PRIMARY KEY,
    count Number default 1
);
CREATE TABLE invoice(
    id NUMBER GENERATED  by default on null as IDENTITY PRIMARY KEY,
    makedBy VARCHAR2(10) NOT NULL REFERENCES WORKER,
    clientBN VARCHAR2(10) NOT NULL REFERENCES "Client",

    dateOfCreation DATE default sysdate not null
);
CREATE TABLE requirement(
    id NUMBER NOT NULL REFERENCES "ORDER",
    discriminator NUMBER ,
    CONSTRAINT pk PRIMARY KEY(id,discriminator),
    invoice NUMBER REFERENCES invoice,

    typeR VARCHAR2(32),
    price int DEFAULT 0 not NULL,
    validity DATE not NULL,
    tempWorkers int DEFAULT 0,
    state VARCHAR2(32) DEFAULT 'received'
);
CREATE TABLE Requirement_Department_bind (
    requirementID NUMBER not NULL,
    requirementDiscriminator NUMBER not NULL,
    FOREIGN KEY (requirementID,requirementDiscriminator) REFERENCES requirement(id, discriminator),
    departmentKEY NUMBER not NULL REFERENCES department,
    CONSTRAINT primerKey PRIMARY KEY(requirementID,requirementDiscriminator,departmentKEY)
);
CREATE OR REPLACE TRIGGER requirement_generate_sequence
AFTER INSERT ON "ORDER" FOR EACH ROW
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('inserting new counter' || :new.id);
    INSERT INTO requirement_counters (id) VALUES (:new.id);
end;
/
CREATE OR REPLACE TRIGGER requirement_insertion
BEFORE INSERT On requirement FOR EACH ROW
DECLARE
    cnt NUMBER;
BEGIN
    SELECT count INTO :new.discriminator FROM requirement_counters WHERE id=:new.id;
    SELECT count INTO cnt FROM requirement_counters WHERE id=:new.id;
    UPDATE requirement_counters set count=cnt+1 where id=:new.id;
end;
/
CREATE OR REPLACE TRIGGER requirement_update
BEFORE UPDATE On requirement FOR EACH ROW
DECLARE
    discriminatorChange EXCEPTION;
BEGIN
    IF :old.discriminator <> :new.discriminator THEN
        RAISE discriminatorChange;
    end if;
    EXCEPTION WHEN discriminatorChange then
        dbms_output.PUT_LINE('Trying to modify internally managed key');
end;
/
 -- computes finalPrice for given order as sum of requirement costs and adds addtional_costs
CREATE OR REPLACE PROCEDURE computeFinalPrice (Order_id Requirement.id%TYPE, additional_costs INT)
AS
    final_price "ORDER".finalPrice%TYPE;
    noSuchOrder exception;
    found_id number;
BEGIN
    Select COUNT(*) into found_id from "ORDER" where id=Order_id;
    if found_id <> 1 then
        raise noSuchOrder;
    end if;
    SELECT SUM(price) INTO final_price FROM REQUIREMENT where id=Order_id;
    DBMS_OUTPUT.PUT_LINE('Total costs of infividual requirements: ' || final_price);
    final_price := final_price + additional_costs;
    UPDATE "ORDER" set finalPrice=final_price where id=Order_id;
    exception when noSuchOrder then
        DBMS_OUTPUT.PUT_LINE('No such order exists in the system.');
END;
/
-- Prints to the output how much given department already made
CREATE OR REPLACE PROCEDURE computeDepartmentEarnings(department_id IN Department.id%TYPE)
IS
    CURSOR cur IS SELECT * from Requirement_Department_bind where departmentKEY=department_id;
    cur_row Requirement_Department_bind%ROWTYPE;
    sum_price number;
    current_price number;
BEGIN
    OPEN cur;
    sum_price := 0;
    LOOP
        FETCH cur INTO cur_row;
        EXIT WHEN cur%NOTFOUND;
        SELECT price INTO current_price FROM REQUIREMENT WHERE id=cur_row.requirementID and discriminator=cur_row.requirementDiscriminator;
        sum_price := sum_price + current_price;
    end loop;
    CLOSE cur;
    DBMS_OUTPUT.PUT_LINE('Department made: ' || sum_price);
END;
/
--------------example data----------

insert into person(birthNum,firstName,lastName,email,phoneNum,city,psc,street,streetNum) values ('8003231379','Carl','Johnson','cj@email.cz','+4201234-56789','San Andreas','12345','grove street','127/I');
insert into person(birthNum,firstName,MIDNAME,lastName,email,phoneNum,city,psc,street,streetNum) values ('7908031846','Franta','Pepa','Jenicka','franta@gmail.com','+4201454-56789','Brno','66345','hradecka','62');
insert into person(birthNum,firstName,email,phoneNum,city,psc,street,streetNum) values ('6151238280','Dana','dana@gmail.com','+4201454-56789','Brno','12345','hradecka','62');
insert into person(birthNum,firstName,email,phoneNum,city,psc,street,streetNum) values ('6651173529','Hana','hana@gmail.com','+42034-56789','Praha','64563','hradecka','62');
insert into person(birthNum,firstName,email,phoneNum,city,psc,street,streetNum) values ('9861263478','Jana','jana@gmail.com','+420454-56789','Kardaska','24567','hradecka','62');

insert into person(birthNum,firstName,email,phoneNum,city,psc,street,streetNum) values ('6611241670','honza','test2@email.cz','+420987654321','praha','54321','nemam rad pondeli','123');
insert into person(birthNum,firstName,email,phoneNum,city,psc,street,streetNum) values ('6812247849','Racna','test3@email.cz','+42848949421','cB','45645','Palirenska','123');
insert into person(birthNum,firstName,lastName,email,phoneNum,city,psc,street,streetNum) values ('9354205960','Lenka','Novakova','test4@email.cz','+420494841','cB','45645','Palirenska','123');
insert into person(birthNum,firstName,lastName,email,phoneNum,city,psc,street,streetNum) values ('9760201077','Eliska','Hyankova','test5@email.cz','+42044988421','cB','45645','Palirenska','123');
--SELECT * from person;

INSERT INTO DEPARTMENT(nameD,descriptionD,room) VALUES ('main department','Toto je hlavni oddeleni.',201);
INSERT INTO DEPARTMENT(nameD,descriptionD,room) VALUES ('secondary department','Toto je vedlejsi oddeleni.',301);
--SELECT * from DEPARTMENT;

insert into worker(workingIn,birthNum,specialization,title,wage) VALUES (1,'8003231379','coffee maker','bc','11000');
insert into worker(workingIn,leads,birthNum,specialization,title,wage) VALUES (1,1,'7908031846','leader','ing','33000');

insert into worker(workingIn,leads,birthNum,specialization,title,wage) VALUES (2,2,'6151238280','leader','ing','33000');
insert into worker(workingIn,birthNum,specialization,title,wage) VALUES (2,'6651173529','front-end','bc','25000');
insert into worker(workingIn,birthNum,specialization,wage) VALUES (2,'9861263478','back-end','20000');
--SELECT * from worker;

insert into "Client"(birthNum) VALUES ('6611241670');
insert into "Client"(birthNum) VALUES ('6812247849');
insert into "Client"(birthNum) VALUES ('9354205960');
insert into "Client"(birthNum) VALUES ('9760201077');
--SELECT * from "Client";

insert into "ORDER"(clientBN,workerBN,finalPrice,deadLine) values ('6611241670','8003231379',50000,TO_DATE('2021/3/10','yyyy/mm/dd'));
insert into "ORDER"(clientBN,workerBN,finalPrice,deadLine) values ('6611241670','8003231379',60000,TO_DATE('2021/6/18','yyyy/mm/dd'));
insert into "ORDER"(clientBN,workerBN,finalPrice,deadLine,dateOfCreation) values ('6812247849','7908031846',70000,TO_DATE('2022/7/18','yyyy/mm/dd'),TO_DATE('2020/7/18','yyyy/mm/dd'));
insert into "ORDER"(clientBN,workerBN,finalPrice,deadLine,state) values ('9354205960','6151238280',60000,TO_DATE('2019/8/24','yyyy/mm/dd'),'finished');
--SELECT * from "ORDER";

insert into requirement(id,price,typeR,validity) values (1,5000,'Bilboard',TO_DATE('2021/3/10','yyyy/mm/dd'));
insert into requirement(id,price,typeR,validity) values (1,6000,'propaganda',TO_DATE('2021/4/10','yyyy/mm/dd'));
insert into requirement(id,price,typeR,validity,state,tempWorkers) values (1,7000,'Internet ad',TO_DATE('2021/2/10','yyyy/mm/dd'),'work in progress',3);

insert into requirement(id,price,typeR,validity) values (2,5000,'Bilboard',TO_DATE('2021/3/10','yyyy/mm/dd'));
insert into requirement(id,price,typeR,validity) values (2,6000,'propaganda',TO_DATE('2021/4/10','yyyy/mm/dd'));
insert into requirement(id,price,typeR,validity,state,tempWorkers) values (2,7000,'Internet ad',TO_DATE('2021/2/10','yyyy/mm/dd'),'work in progress',3);
insert into requirement(id,price,typeR,validity,state,tempWorkers) values (2,10000,'Magazine ad',TO_DATE('2021/1/10','yyyy/mm/dd'),'finished',5);

insert into requirement(id,price,typeR,validity) values (3,5000,'plakat',TO_DATE('2021/3/10','yyyy/mm/dd'));
insert into requirement(id,price,typeR,validity) values (3,6000,'neco',TO_DATE('2021/4/10','yyyy/mm/dd'));
insert into requirement(id,price,typeR,validity,state,tempWorkers) values (3,7000,'nevim',TO_DATE('2021/2/10','yyyy/mm/dd'),'work in progress',3);
insert into requirement(id,price,typeR,validity,state,tempWorkers) values (3,10000,'tohle',TO_DATE('2021/1/10','yyyy/mm/dd'),'finished',5);

--SELECT * from requirement;

insert into invoice(makedBy,clientBN) values ('8003231379','6611241670');
insert into invoice(makedBy,clientBN) values ('8003231379','6812247849');
insert into invoice(makedBy,clientBN) values ('8003231379','6812247849');
--SELECT * from invoice;

UPDATE requirement SET invoice=1 WHERE (id,discriminator) in ((1,1),(1,3));
UPDATE requirement SET invoice=2 WHERE (id,discriminator) in ((3,8),(3,9));
UPDATE requirement SET invoice=3 WHERE (id,discriminator) in ((3,10),(3,11));
--SELECT * from requirement;

insert into Requirement_Department_bind (requirementID,requirementDiscriminator,departmentKEY) VALUES (1,1,1);
--SELECT * from Requirement_Department_bind ;

--------------select----------------

SELECT DISTINCT REQ.* FROM "ORDER" O,REQUIREMENT REQ WHERE REQ.id=O.id AND O.id=1 ;  --zobraz vsechny pozadavky z objednavky c.1
SELECT DISTINCT I.* FROM invoice I,"Client" CLI WHERE CLI.birthNum=I.clientBN AND CLI.birthNum='6812247849';  --faktury uzivatele s rodnym cislem 6812247849
SELECT DISTINCT REQ.* FROM requirement REQ,"ORDER" O,"Client" CLI WHERE CLI.birthNum=O.clientBN AND CLI.birthNum='6611241670' AND O.id=REQ.id;    --zobrazi vsechny pozadavky klienta s rodnym cislem 6611241670
SELECT P.firstName, CLI.birthNum,COUNT(*) pocet, SUM(PRICE) celkem from PERSON P,"Client" CLI,"ORDER" O,REQUIREMENT REQ where P.birthNum=CLI.birthNum AND CLI.birthNum=O.clientBN AND O.id=REQ.id GROUP BY CLI.birthNum,P.firstName; --zobrazi pocet pozadavků a celkovou cenu u kazdeho klienta
SELECT D.nameD,D.id,COUNT(*) pocetPracovniku,SUM(WAGE) nakladyNaMzdy from department D, WORKER W WHERE  W.workingIn=D.id GROUP BY D.nameD,D.id ;    --zobrazi u kazdeho odeleni pocet pracovniků a celkove naklady na mzdy
SELECT P.firstName,P.lastName, CLI.birthNum,P.phoneNum,P.email from PERSON P,"Client" CLI WHERE  P.birthNum=CLI.birthNum AND NOT EXISTS(SELECT * from "ORDER" ORD WHERE ORD.clientBN=CLI.birthNum); --vypise klienty, kteri si nic neobjednali a jejich kontaktni údaje 
SELECT * FROM  "Client" WHERE BIRTHNUM in (SELECT clientBN FROM "ORDER" WHERE DEADLINE BETWEEN TO_DATE('2021-01-01','yyyy/mm/dd') AND TO_DATE('2021-12-30','yyyy/mm/dd'));  --Vypise rodna cisla klientů, kteri v roce 2021 umistili objednavku/y
SELECT DISTINCT p.firstName,p.lastName,p.email from WORKER w, PERSON p where w.birthNum=p.birthNum and EXISTS (Select O.workerBN from "ORDER" O where workerBN=w.birthNum and state!='finished'); --vypise vsetkych pracovnikov, ktori maju na starosti neukoncenu objednavku
SELECT p.firstName,p.lastName,p.birthNum from "Client" c,PERSON p where c.birthNum=p.birthNum and c.birthNum IN (SELECT clientBN from (SELECT O.clientBN, SUM(O.finalPrice) totalSum from "ORDER" O group by O.clientBN) where totalSum>100000); --zobraz klientov, ktori uz v agenture utratili viac ako 100 000Kc

------------demonstration of procedures---------
BEGIN
    computeFinalPrice(2, 30000);
    computeDepartmentEarnings(1);
end;
/
--------- roles of system that acts on behalf of user, additional security checks are necessary ---------
GRANT SELECT, INSERT, DELETE ON "ORDER" TO XKOMAR33;
GRANT SELECT, INSERT, DELETE ON "REQUIREMENT" TO XKOMAR33;
GRANT SELECT ON "INVOICE" TO XKOMAR33;
GRANT UPDATE ON "PERSON" TO XKOMAR33;

-------- materialized view for other user -----------
-- CREATE MATERIALIZED VIEW activeRequirements AS SELECT * from XLACKO09."ORDER" O, XLACKO09.REQUIREMENT WHERE O.state!='finished';

-------- index performance --------------------------
SELECT COUNT(*) noOfPeople, p.city FROM PERSON p, "Client" c where p.birthNum=c.birthNum GROUP BY p.city;
CREATE INDEX person_city_I ON "PERSON"(city);
SELECT COUNT(*) noOfPeople, p.city FROM PERSON p, "Client" c where p.birthNum=c.birthNum GROUP BY p.city;

commit;