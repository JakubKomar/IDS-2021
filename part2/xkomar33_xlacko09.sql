BEGIN
FOR rec IN (SELECT table_name from user_tables)
LOOP
    DBMS_OUTPUT.PUT_LINE('Removing: ' || rec.TABLE_NAME);
    EXECUTE IMMEDIATE 'DROP TABLE "' || rec.TABLE_NAME || '" CASCADE CONSTRAINTS';
END LOOP;
END;
/
CREATE TABLE person (
    birthNum NUMBER(10,0) PRIMARY KEY,

    firstName VARCHAR2(32) not NULL,
    midName VARCHAR(32),
    lastName VARCHAR(32),
    email VARCHAR(32) not NULL,
    phoneNum VARCHAR(15) not NULL,
    city VARCHAR(32) not NULL,
    psc NUMBER(5,0) not NULL,
    street VARCHAR(32) not NULL,
    streetNum VARCHAR(10) not NULL,

    CHECK (birthNum>999999999),
    CHECK (mod(birthNum,11)=0),
    CHECK (regexp_like(phoneNum,'^\+?[0-9|-]*$')),
    CHECK (regexp_like(email,'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')),
    CHECK (psc>9999)
);
CREATE TABLE myClient (
    birthNum INT NOT NULL PRIMARY KEY,
    FOREIGN KEY (birthNum) REFERENCES person
);
CREATE TABLE department(
    id NUMBER GENERATED  by default on null as IDENTITY PRIMARY KEY,

    nameD VARCHAR(32) not NULL,
    descriptionD VARCHAR(64),
    room NUMBER(8),

    CHECK (room>=0)
);
CREATE TABLE worker (
    birthNum INT NOT NULL PRIMARY KEY,
    FOREIGN KEY (birthNum) REFERENCES person,
    workingIn INT NOT NULL ,
    FOREIGN KEY (workingIn) REFERENCES DEPARTMENT,
    leads INT ,
    FOREIGN KEY (leads) REFERENCES DEPARTMENT,

    specialization VARCHAR(32),
    title VARCHAR(10),
    wage NUMBER(8,2) DEFAULT 0 NOT NULL,

    CHECK (wage>=0)
);
CREATE TABLE myOrder (
    id NUMBER GENERATED  by default on null as IDENTITY PRIMARY KEY,
    clientBN INT NOT NULL ,
    FOREIGN KEY (clientBN) REFERENCES myClient,
    workerBN INT NOT NULL ,
    FOREIGN KEY (workerBN) REFERENCES worker,

    finalPrice int DEFAULT 0 ,
    deadLine DATE,
    state VARCHAR(32) DEFAULT 'sended',
    dateOfCreation DATE default sysdate not null
);
CREATE TABLE invoice(
    id NUMBER GENERATED  by default on null as IDENTITY PRIMARY KEY,
    makedBy INT NOT NULL ,
    FOREIGN KEY (makedBy) REFERENCES WORKER,
    clientBN INT NOT NULL ,
    FOREIGN KEY (clientBN) REFERENCES myCLIENT,

    dateOfCreation DATE default sysdate not null
);
CREATE TABLE requirement(
    id NUMBER NOT NULL,
    FOREIGN KEY (id) REFERENCES myOrder,
    discriminator NUMBER GENERATED  by default on null as IDENTITY ,
    CONSTRAINT pk PRIMARY KEY(id,discriminator),
    invoice NUMBER ,
    FOREIGN KEY (invoice) REFERENCES invoice,

    typeR VARCHAR(32),
    price int DEFAULT 0 not NULL,
    validity DATE not NULL,
    tempWorkers int DEFAULT 0,
    state VARCHAR(32) DEFAULT 'received'
);
CREATE TABLE workingOn(
    requirementID NUMBER not NULL,
    requirementDiscriminator NUMBER not NULL,
    FOREIGN KEY (requirementID,requirementDiscriminator) REFERENCES requirement(id, discriminator),
    departmentKEY NUMBER not NULL,
    FOREIGN KEY (departmentKEY) REFERENCES department,
    CONSTRAINT primerKey PRIMARY KEY(requirementID,requirementDiscriminator,departmentKEY)
);


--------------example data----------

insert into person(birthNum,firstName,lastName,email,phoneNum,city,psc,street,streetNum) values (8003231379,'Carl','Johnson','cj@email.cz','+4201234-56789','San Andreas',12345,'grove street','127/I');
insert into person(birthNum,firstName,MIDNAME,lastName,email,phoneNum,city,psc,street,streetNum) values (7908031846,'Franta','Pepa','Jenicka','franta@gmail.com','+4201454-56789','Brno',66345,'hradecka','62');
insert into person(birthNum,firstName,email,phoneNum,city,psc,street,streetNum) values (6151238280,'Dana','dana@gmail.com','+4201454-56789','Brno',12345,'hradecka','62');
insert into person(birthNum,firstName,email,phoneNum,city,psc,street,streetNum) values (6651173529,'Hana','hana@gmail.com','+42034-56789','Praha',64563,'hradecka','62');
insert into person(birthNum,firstName,email,phoneNum,city,psc,street,streetNum) values (9861263478,'Jana','jana@gmail.com','+420454-56789','Kardaska',24567,'hradecka','62');

insert into person(birthNum,firstName,email,phoneNum,city,psc,street,streetNum) values (6611241670,'honza','test2@email.cz','+420987654321','praha',54321,'nemam rad pondeli','123');
insert into person(birthNum,firstName,email,phoneNum,city,psc,street,streetNum) values (6812247849,'Racna','test3@email.cz','+42848949421','cB',45645,'Palirenska','123');
insert into person(birthNum,firstName,lastName,email,phoneNum,city,psc,street,streetNum) values (9354205960,'Lenka','Novakova','test4@email.cz','+420494841','cB',45645,'Palirenska','123');
insert into person(birthNum,firstName,lastName,email,phoneNum,city,psc,street,streetNum) values (9760201077,'Eliska','Hyankova','test5@email.cz','+42044988421','cB',45645,'Palirenska','123');
--SELECT * from person;

INSERT INTO DEPARTMENT(nameD,descriptionD,room) VALUES ('main department','Toto je hlavni oddeleni.',201);
INSERT INTO DEPARTMENT(nameD,descriptionD,room) VALUES ('secondary department','Toto je vedlejsi oddeleni.',301);
--SELECT * from DEPARTMENT;

insert into worker(workingIn,birthNum,specialization,title,wage) VALUES (1,8003231379,'coffee maker','bc','11000');
insert into worker(workingIn,leads,birthNum,specialization,title,wage) VALUES (1,1,7908031846,'leader','ing','33000');

insert into worker(workingIn,leads,birthNum,specialization,title,wage) VALUES (2,2,6151238280,'leader','ing','33000');
insert into worker(workingIn,birthNum,specialization,title,wage) VALUES (2,6651173529,'front-end','bc','25000');
insert into worker(workingIn,birthNum,specialization,wage) VALUES (2,9861263478,'back-end','20000');
--SELECT * from worker;

insert into myClient(birthNum) VALUES (6611241670);
insert into myClient(birthNum) VALUES (6812247849);
insert into myClient(birthNum) VALUES (9354205960);
insert into myClient(birthNum) VALUES (9760201077);
--SELECT * from myClient;

insert into myOrder(clientBN,workerBN,finalPrice,deadLine) values (6611241670,8003231379,20000,TO_DATE('2021/3/10','yyyy/mm/dd'));
insert into myOrder(clientBN,workerBN,finalPrice,deadLine) values (6611241670,8003231379,60000,TO_DATE('2021/6/18','yyyy/mm/dd'));
insert into myOrder(clientBN,workerBN,finalPrice,deadLine,dateOfCreation) values (6812247849,7908031846,70000,TO_DATE('2022/7/18','yyyy/mm/dd'),TO_DATE('2020/7/18','yyyy/mm/dd'));
SELECT * from myOrder;

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

insert into invoice(makedBy,clientBN) values (8003231379,6611241670);
insert into invoice(makedBy,clientBN) values (8003231379,6812247849);
insert into invoice(makedBy,clientBN) values (8003231379,6812247849);
--SELECT * from invoice;

UPDATE requirement SET invoice=1 WHERE (id,discriminator) in ((1,1),(1,3));
UPDATE requirement SET invoice=2 WHERE (id,discriminator) in ((3,8),(3,9));
UPDATE requirement SET invoice=3 WHERE (id,discriminator) in ((3,10),(3,11));
--SELECT * from requirement;

insert into workingOn(requirementID,requirementDiscriminator,departmentKEY) VALUES (1,1,1);
--SELECT * from workingOn;

--------------select----------------
/*
SELECT DISTINCT REQ.* FROM MYORDER O,REQUIREMENT REQ WHERE REQ.id=O.id AND O.id=1 ;  --zobraz vsechny pozadavky z objednavky c.1
SELECT DISTINCT I.* FROM invoice I,MYCLIENT CLI WHERE CLI.birthNum=I.clientBN AND CLI.birthNum=6812247849;  --faktury uzivatele s rodnym cislem 6812247849
SELECT DISTINCT REQ.* FROM requirement REQ,myOrder O,myClient CLI WHERE CLI.birthNum=O.clientBN AND CLI.birthNum=6611241670 AND O.id=REQ.id;    --zobrazi vsechny pozadavky klienta s rodnym cislem 6611241670
SELECT P.firstName, CLI.birthNum,COUNT(*) pocet, SUM(PRICE) celkem from PERSON P,MYCLIENT CLI,MYORDER O,REQUIREMENT REQ where P.birthNum=CLI.birthNum AND CLI.birthNum=O.clientBN AND O.id=REQ.id GROUP BY CLI.birthNum,P.firstName; --zobrazi pocet pozadavků a celkovou cenu u kazdeho klienta
SELECT D.nameD,D.id,COUNT(*) pocetPracovniku,SUM(WAGE) nakladyNaMzdy from department D, WORKER W WHERE  W.workingIn=D.id GROUP BY D.nameD,D.id ;    --zobrazi u kazdeho odeleni pocet pracovniků a celkove naklady na mzdy
SELECT P.firstName,P.lastName, CLI.birthNum,P.phoneNum,P.email from PERSON P,MYCLIENT CLI WHERE  P.birthNum=CLI.birthNum AND NOT EXISTS(SELECT * from MYORDER ORD WHERE ORD.clientBN=CLI.birthNum); --vypise klienty, kteri si nic neobjednali a jejich kontaktni údaje 
SELECT * FROM  MYCLIENT WHERE BIRTHNUM in (SELECT clientBN FROM myOrder WHERE DEADLINE BETWEEN TO_DATE('2021-01-01','yyyy/mm/dd') AND TO_DATE('2021-12-30','yyyy/mm/dd'));  --Vypise rodna cisla klientů, kteri v roce 2021 umistili objednavku/y
*/
