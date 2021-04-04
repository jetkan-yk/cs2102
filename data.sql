DELETE FROM Sessions;

DELETE FROM Offerings;

DELETE FROM Courses;

DELETE FROM Course_areas;

DELETE FROM Administrators;

DELETE FROM Rooms;

DELETE FROM Customers;

DELETE FROM Credit_cards;

DELETE FROM Owns;

DELETE FROM Registers;

DELETE FROM Cancels;

DELETE FROM Buys;

DELETE FROM Course_packages;

DELETE FROM Redeems;

INSERT INTO Course_areas (area_name)
VALUES ('Artificial Intelligence'),
  ('Computer Graphics and Games'),
  ('Computer Security'),
  ('Database Systems'),
  ('Software Engineering');

INSERT INTO Courses (
    title,
    description,
    duration,
    area_name
  )
VALUES (
    'Introduction to Database Systems',
    'The aim of this module is to introduce the fundamental concepts and techniques necessary for the understanding and practice of design and implementation of database systems.',
    2,
    'Database Systems'
  ),
  (
    'Introduction to Information Security',
    NULL,
    2,
    'Computer Security'
  ),
  (
    'Advanced Computer Security',
    'The objective of this module is to provide a broad understanding of computer security with some indepth discussions on selected topics in system and network security.',
    3,
    'Computer Security'
  ),
  (
    '3D Modelling and Animation',
    'This module aims to provide fundamental concepts in 3D modeling and animation. It also serves as a bridge to advanced media modules.',
    5,
    'Computer Graphics and Games'
  ),
  (
    'Machine Learning',
    'This module introduces basic concepts and algorithms in machine learning and neural networks.',
    6,
    'Artificial Intelligence'
  ),
  (
    'Software Testing',
    'This module covers the concepts and practice of software testing including unit testing, integration testing, and regression testing.',
    4,
    'Software Engineering'
  ),
  (
    'Big Data Systems for Data Science',
    'Data science incorporates varying elements and builds on techniques and theories from many fields with the goal of extracting meaning from big data and creating data products.',
    5,
    'Database Systems'
  ),
  (
    'Cryptography Theory and Practice',
    'This module aims to introduce the foundation, principles and concepts behind cryptology and the design of secure communication systems.',
    1,
    'Computer Security'
  ),
  (
    'Natural Language Processing',
    'This module deals with computer processing of human languages, emphasizing a corpus-based empirical approach.',
    7,
    'Artificial Intelligence'
  ),
  (
    'Uncertainty Modelling in AI',
    'The module covers modelling methods that are suitable for reasoning with uncertainty.',
    5,
    'Artificial Intelligence'
  );

INSERT INTO Rooms (rid, location, seating_capacity)
VALUES (1, '1F-01', 20),
  (2, '1F-02', 10),
  (3, '1F-03', 15),
  (4, '1F-04', 25),
  (5, '2F-01', 50),
  (6, '2F-02', 40),
  (7, '2F-03', 25),
  (8, '2F-04', 25),
  (9, '3F-01', 100),
  (10, '3F-02', 100);

INSERT INTO Administrators (eid)
VALUES (1),
  (2),
  (3),
  (4),
  (5),
  (6),
  (7),
  (8),
  (9),
  (10);

INSERT INTO Offerings (
    course_id,
    offering_id,
    launch_date,
    reg_deadline,
    fees,
    target_num_reg,
    eid
  )
VALUES (1, 1242, '2021-02-07', '2021-04-22', 260, 198, 3),
  (1, 2317, '2021-01-10', '2021-04-10', 320, 101, 1),
  (2, 4248, '2021-02-28', '2021-05-29', 190, 141, 2),
  (3, 4248, '2021-02-27', '2021-06-04', 400, 137, 8),
  (4, 3235, '2021-03-17', '2021-04-11', 170, 24, 5),
  (5, 3242, '2021-03-20', '2021-06-03', 285, 110, 5),
  (5, 3757, '2021-01-31', '2021-06-30', 400, 112, 1),
  (5, 4236, '2021-01-12', '2021-05-26', 170, 61, 5),
  (6, 4218, '2021-01-30', '2021-05-27', 460, 153, 4),
  (8, 4225, '2021-03-12', '2021-06-15', 75, 23, 7),
  (8, 4236, '2021-02-28', '2021-06-23', 440, 127, 4),
  (9, 2317, '2021-02-10', '2021-04-03', 200, 51, 9),
  (9, 5340, '2021-03-15', '2021-06-04', 270, 171, 6),
  (10, 6585, '2021-02-07', '2021-06-23', 125, 73, 9);

INSERT INTO Sessions (
    course_id,
    offering_id,
    session_date,
    start_time,
    rid
  )
VALUES (1, 1242, '2021-08-04', '10:00', 1),
  (1, 2317, '2021-07-01', '10:00', 3),
  (1, 2317, '2021-07-01', '14:00', 3),
  (1, 2317, '2021-08-30', '09:00', 6),
  (1, 2317, '2021-09-15', '14:00', 2),
  (2, 4248, '2021-08-09', '09:00', 8),
  (3, 4248, '2021-07-31', '15:00', 4),
  (3, 4248, '2021-08-09', '10:00', 5),
  (3, 4248, '2021-09-09', '15:00', 1),
  (3, 4248, '2021-09-18', '09:00', 9),
  (3, 4248, '2021-09-23', '16:00', 5),
  (3, 4248, '2021-09-25', '15:00', 9),
  (4, 3235, '2021-07-28', '11:00', 2),
  (4, 3235, '2021-08-01', '14:00', 8),
  (5, 3242, '2021-07-12', '16:00', 10),
  (5, 3242, '2021-08-27', '16:00', 5),
  (5, 3242, '2021-09-26', '14:00', 5),
  (5, 3242, '2021-09-28', '09:00', 4),
  (5, 3757, '2021-07-15', '10:00', 3),
  (5, 3757, '2021-08-07', '09:00', 10),
  (5, 3757, '2021-08-12', '10:00', 8),
  (5, 3757, '2021-09-03', '10:00', 4),
  (5, 3757, '2021-09-29', '11:00', 5),
  (5, 4236, '2021-07-25', '10:00', 2),
  (5, 4236, '2021-07-29', '09:00', 5),
  (6, 4218, '2021-09-30', '16:00', 4),
  (8, 4225, '2021-08-26', '11:00', 5),
  (8, 4225, '2021-09-27', '09:00', 1),
  (8, 4236, '2021-07-05', '11:00', 8),
  (8, 4236, '2021-07-11', '14:00', 5),
  (8, 4236, '2021-09-30', '10:00', 3),
  (9, 2317, '2021-07-13', '10:00', 9),
  (9, 2317, '2021-08-10', '16:00', 3),
  (9, 2317, '2021-08-24', '09:00', 9),
  (9, 2317, '2021-09-05', '14:00', 1),
  (9, 5340, '2021-08-13', '09:00', 10),
  (9, 5340, '2021-08-18', '14:00', 4),
  (10, 6585, '2021-07-05', '14:00', 4),
  (10, 6585, '2021-08-09', '15:00', 5),
  (10, 6585, '2021-08-12', '17:00', 3),
  (10, 6585, '2021-08-27', '15:00', 9),
  (10, 6585, '2021-09-13', '17:00', 1);

/*
Commenting away the empty INSERT queries to
suppress errors when running \i data.sql

INSERT INTO Customers (
  cust_id,
  name,
  address,
  phone,
  email
)
VALUES ("04533","Faith Graves","P.O. Box 146, 6550 Gravida St.","16900205 8742","porta.elit@Crasvulputatevelit.ca"),("64715","Martha Guy","2841 Ultrices. Road","16540218 1753","mollis.Phasellus.libero@hymenaeosMaurisut.org"),("95258","Hall Savage","903-4888 Proin Ave","16830401 9113","in.felis.Nulla@Sed.net"),("84828","Holly Daugherty","Ap #214-8751 Nec Ave","16150328 6989","diam@rutrumurnanec.net"),("25027","Anjolie Carlson","Ap #915-3742 Ipsum Avenue","16850507 0535","nisi@sapienAenean.edu"),("54068","Bernard Pate","530-193 Sapien. Road","16150311 4694","scelerisque@pedeCumsociis.com"),("90051","Indira Mckee","9415 Orci Rd.","16970612 5912","felis.Nulla.tempor@arcuimperdiet.edu"),("88106","Uma Weeks","P.O. Box 793, 1381 Sit Road","16080720 2395","imperdiet@egetnisi.co.uk"),("60405","Ariana Spencer","Ap #871-1904 Lobortis Avenue","16110924 2626","vel.turpis.Aliquam@acturpisegestas.edu"),("78734","Levi Avery","4394 Adipiscing Av.","16361127 2794","est.ac@Donecest.com");
("25064","Rama Montgomery","P.O. Box 451, 7783 Nec, Street","16690312 0092","ante.dictum.cursus@temporerat.co.uk"),("46980","Yael Riggs","3185 Integer Street","16050407 0384","nisi@musProin.edu"),("02252","Sydnee Trujillo","5735 Enim. St.","16670225 9893","neque.venenatis.lacus@Morbiquis.com"),("25358","Kaye Gonzalez","6369 Imperdiet Avenue","16480324 8857","ornare.tortor@nonummyut.com"),("73705","Maisie Sharpe","597-4975 Phasellus Road","16050922 7682","risus.a.ultricies@pellentesque.org"),("95068","Hoyt Forbes","P.O. Box 304, 5271 Mauris Rd.","16610711 7407","nisi.nibh.lacinia@molestiearcuSed.ca"),("89085","Serina Maddox","Ap #674-2014 Posuere St.","16140706 6719","mauris.blandit.mattis@inceptoshymenaeosMauris.com"),("06772","Cullen Hewitt","P.O. Box 413, 2773 Dis Road","16501123 0009","a.feugiat@ornare.co.uk"),("62519","Cally Wall","685-1990 Ligula Ave","16571118 8473","Fusce@velquam.org"),("03426","Bert Perkins","4840 Erat Avenue","16110918 6450","scelerisque@risus.edu");
("81034","Jacob Calderon","Ap #219-3317 Est Rd.","16110813 8106","et.malesuada.fames@diamdictum.org"),("17860","Herman Kline","1359 Libero Ave","16390820 7271","tempus@Loremipsum.net"),("51836","Jolene Burns","P.O. Box 160, 9780 Feugiat St.","16830407 5156","Proin.mi@auctor.net"),("09793","Carol Banks","Ap #513-1974 Dictum St.","16530430 3331","tincidunt@cursus.edu"),("86093","Kato Barron","P.O. Box 204, 5699 Natoque Road","16091013 6860","tempus.eu@dapibus.com"),("65786","Noel Lindsey","P.O. Box 618, 8360 Gravida. St.","16761115 8077","ipsum.Suspendisse@necquamCurabitur.net"),("79426","Beau Foley","P.O. Box 899, 4533 Consectetuer Street","16860902 6342","leo.elementum@Quisquepurus.edu"),("37774","Branden Owen","Ap #155-6344 Libero Av.","16600229 3907","ipsum@neque.net"),("69957","Holly Hobbs","656-2149 Primis St.","16260914 0906","Vestibulum.ante@Praesenteu.com"),("91249","Vladimir Vasquez","Ap #618-6764 Proin Av.","16040607 9285","Nulla.eu@Crasinterdum.org");
("88343","Rogan Valenzuela","864-6949 Auctor St.","16420628 8229","scelerisque.sed.sapien@Nullam.co.uk"),("33971","Xanthus Christensen","2879 Dis Ave","16850616 7546","dui.Fusce.diam@Inornaresagittis.co.uk"),("08677","Tyrone Watkins","P.O. Box 927, 8311 Odio Ave","16811022 6605","torquent.per@justosit.co.uk"),("07761","Russell Blake","P.O. Box 479, 542 Eu Rd.","16180505 7450","et.commodo@idblandit.edu"),("09730","Karen Ferguson","134-5790 Nullam Street","16880901 9139","fames.ac@risus.ca"),("94868","Amelia Salazar","Ap #456-8918 Sapien, Avenue","16520201 8890","pharetra@arcuVestibulumut.co.uk"),("99572","Thomas Fletcher","203-2217 Eu Road","16060730 7907","metus.In.lorem@Cumsociis.net"),("45579","Halla Holder","960-583 Ligula Road","16080320 6911","Nunc.lectus@Duis.org"),("92716","William Gentry","P.O. Box 874, 5451 Suspendisse Ave","16411113 5879","justo.sit@nascetur.ca"),("14909","Minerva Barber","7151 Lacus. St.","16300107 7134","dignissim@idlibero.org");
("23558","Brenden Clark","594-3601 Dis St.","16740317 3631","orci@neque.net"),("74221","Wang Mayer","3782 Ac Rd.","16251119 7069","nascetur.ridiculus@nibhQuisquenonummy.ca"),("35240","Demetrius Wolf","P.O. Box 701, 4255 Nam Street","16760929 4827","tellus.lorem.eu@odiosempercursus.com"),("35468","Amir Mccray","P.O. Box 556, 2360 Ac Avenue","16110619 4408","nibh@pede.edu"),("45020","Duncan Guy","P.O. Box 799, 5129 Convallis Ave","16611119 1307","nec@elitEtiamlaoreet.org"),("83730","Marvin Benton","6123 Arcu St.","16010108 0091","Fusce.aliquam@diam.com"),("64562","Rhiannon Nash","7338 Laoreet Street","16941028 7123","risus.quis@lorem.ca"),("05682","Julie Rogers","Ap #284-9563 Sagittis. Avenue","16821224 6600","placerat.velit@Etiamvestibulummassa.edu"),("73222","Paki Ochoa","3509 Malesuada St.","16380613 7943","massa.Integer.vitae@quamelementum.net"),("23854","Kai Calderon","452-754 Enim St.","16670501 6787","Nam.ligula.elit@commodo.edu");
("46101","Gannon Moon","2080 Risus. Rd.","16380910 5756","venenatis.a@justoProin.org"),("44539","Fletcher Warren","P.O. Box 540, 7507 In Street","16961123 1755","Morbi.vehicula@Nuncullamcorpervelit.co.uk"),("11544","Honorato Boyd","P.O. Box 751, 7018 Placerat. Ave","16570808 5237","vel.nisl@Proin.co.uk"),("13150","Jermaine Wall","3577 Velit. Rd.","16300629 7331","diam.Duis.mi@velpedeblandit.co.uk"),("94477","Clayton Norman","2866 Aliquam Rd.","16030925 5438","libero@orci.co.uk"),("71063","Chadwick Bates","417-7270 Eget Street","16291211 7609","ut.pharetra@magnaLoremipsum.net"),("00658","Anastasia Nelson","Ap #857-6312 Vel St.","16810822 1022","libero.mauris.aliquam@sedtortor.org"),("58777","Jolene Gill","2794 Orci, Avenue","16170415 9860","nibh.Phasellus.nulla@tempusmauris.org"),("37640","Ferris Walter","Ap #323-7667 Eros Road","16200120 0704","iaculis@diam.edu"),("48534","Rashad Lindsey","P.O. Box 463, 435 Duis Av.","16000607 3522","dignissim.Maecenas.ornare@orciconsectetuereuismod.edu");
("89635","Aurelia Cameron","P.O. Box 519, 6149 Fringilla Rd.","16130127 3965","id.nunc.interdum@imperdiet.edu"),("71566","Macon Ashley","512-9038 Nisl. Road","16220206 2952","amet.consectetuer@velit.ca"),("48197","Reagan Dyer","P.O. Box 929, 529 Eu Road","16350921 1987","sed.facilisis.vitae@InfaucibusMorbi.com"),("34146","Remedios Burgess","765-2830 Nisl. Avenue","16530402 7724","turpis.In.condimentum@Phasellus.ca"),("70533","Aidan Ware","Ap #653-8969 Consequat Rd.","16500820 4199","vestibulum@dictum.net"),("72205","Hannah Alvarado","P.O. Box 232, 6845 Luctus, Rd.","16020227 6846","nec.mauris.blandit@nibhPhasellus.com"),("03531","Vivian Sweet","P.O. Box 801, 3614 Magna St.","16230129 7772","massa@PhasellusnullaInteger.net"),("57085","Jasmine Sims","P.O. Box 912, 6481 Aliquet Av.","16050305 4843","justo@auctor.com"),("35622","Thaddeus Whitney","P.O. Box 885, 7380 Diam Street","16421114 5869","Mauris@Duisami.edu"),("49961","Whoopi Jackson","P.O. Box 973, 388 Luctus. Rd.","16760220 9988","aliquet@nonummy.edu");
("52523","Luke Dickerson","P.O. Box 916, 2439 Accumsan Ave","16390817 9157","tellus.Aenean.egestas@consectetuermaurisid.net"),("92210","Dara Lee","5101 Ut Ave","16610520 5808","gravida.sit@Proinnonmassa.net"),("23343","Cade Walsh","Ap #882-6922 Consectetuer Avenue","16010130 5712","est.mollis.non@sapien.edu"),("38028","Madonna Hampton","Ap #203-6302 Lorem, St.","16000229 4478","est.ac.mattis@nonbibendum.edu"),("15105","Darius Perez","Ap #634-9242 Justo Street","16370709 3781","sed@imperdiet.ca"),("20054","Brenna Kinney","Ap #186-3114 Nunc Street","16030328 5225","mi@Phasellus.ca"),("16847","Jamal Koch","Ap #619-2342 Pede St.","16490924 2259","penatibus.et.magnis@odioNaminterdum.net"),("87064","Raven Santos","808 Ut Ave","16420812 1964","Nunc.quis@aliquetodio.co.uk"),("53151","Tyrone Merrill","270-5162 Vel, Rd.","16080617 7218","libero@diamProindolor.co.uk"),("18077","Willow Ruiz","P.O. Box 768, 9971 Dictum. St.","16980817 4438","ipsum.dolor.sit@adipiscinglobortis.ca");
("88497","Maile Lynn","P.O. Box 657, 1392 Proin Street","16320518 2003","Donec.luctus.aliquet@ornare.co.uk"),("57489","Ifeoma Clemons","Ap #767-2324 Nulla Avenue","16010514 0420","faucibus.orci.luctus@eget.com"),("85946","Lacey Bush","Ap #154-2487 Nam Street","16880414 0443","sed@nisia.co.uk"),("90633","Lynn Turner","Ap #326-9553 Tempus Street","16150801 8098","vitae@etnetus.edu"),("94761","Charlotte Gay","211-6542 Neque Rd.","16640509 7046","nec@vitae.co.uk"),("98577","Magee Nichols","316-6682 Viverra. Rd.","16931009 7564","magna@nondapibusrutrum.com"),("19100","Evelyn Glenn","Ap #891-7851 Nec, Street","16210313 9792","ligula.eu@ipsumprimis.co.uk"),("55583","Colorado Schmidt","792-7035 Tellus Road","16920813 9460","ac@Curabitur.net"),("78678","Minerva Wilcox","P.O. Box 492, 3565 Dictum Ave","16440919 8282","aptent.taciti@aliquam.org"),("09784","Uma Walton","Ap #425-7812 Erat St.","16120106 1148","nisi@Crasinterdum.org");
("07560","Hamilton Russo","323-8361 Primis Ave","16690315 3697","facilisis@lacinia.edu"),("43173","Francesca Moreno","P.O. Box 702, 512 Aliquam Av.","16811117 1560","ac@sedpede.org"),("51931","Bevis Oneill","474-4227 Non, St.","16020506 6152","dolor.Donec.fringilla@dictummi.net"),("93914","Owen Gallagher","Ap #752-1868 Enim, Street","16560402 2912","euismod.et.commodo@tinciduntduiaugue.edu"),("82913","Murphy Solis","4519 Fermentum Road","16980613 4582","tellus.eu@fringillacursus.com"),("55152","Cooper Golden","P.O. Box 926, 2774 Non, Road","16080809 3264","pretium.et.rutrum@dolorelit.edu"),("03350","John Eaton","P.O. Box 952, 3703 Et Av.","16360608 8064","ornare@viverraDonectempus.ca"),("68732","Tiger Glover","5414 Fusce Rd.","16800510 0865","erat.nonummy@massa.ca"),("89157","Herman Johnson","657-376 Hendrerit Ave","16020612 7953","dolor.sit.amet@Mauriseuturpis.com"),("54120","Lareina Mullen","P.O. Box 181, 4576 Interdum Road","16620402 7251","ornare@sitamet.ca");

INSERT INTO Credit_cards (
  cc_number,
  CVV,
  expiry_date
)
VALUES ();

INSERT INTO Owns (
  cc_number,
  cust-id,
  from_date
)
VALUES ();

INSERT INTO Registers (
  reg_date,
  cc_number,
  course_id,
  offering_id,
  session_id
)
VALUES ();

INSERT INTO Cancels (
  cancel_date,
  refund_amt,
  package_credit,
  cust_id
)
VALUES ();

INSERT INTO Buys (
  buy_date,
  num_free_registrations,
  num_remaining_redemptions,
  package_id,
  cc_number
)
VALUES ();

INSERT INTO Course_packages (
  package_id,
  num_free_registrations,
  sale_start_date,
  sale_end_date,
  name,
  price
)
VALUES ();

INSERT INTO Redeems (
  redeem_date,
  package_id,
  cc_number,
  buy_date,
  course_id,
  offering_id,
  session_id
)
VALUES ();

*/
