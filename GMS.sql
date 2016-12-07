/*需求分析
此数据库需要满足宾管对客房信息的管理，因此客房需要有客房类型，价目信息，客房信息，客房的状态，折扣等数据项。对于每一个入住的客户，要对每个客户的信息进行维护管理，客户信息中应包含房间等信息。还需要独立的维护入住和退房的这两个操作。对于资金的出入也需要一个费用管理表来维护。
当有客户入住时，操作客户表，同时通过触发器更新入住表和费用表。当客户退房时，操作客户表，通过触发器更新退房表和费用表。
宾馆要了解各种类型的客房的受欢迎程度，我们建立一个储存过程，接受两个完整的时间参数，用于统计该时间段内各种类型客房的入住天数和合计和费用合计。为了方便前台对客户进行入住操作，建立一个视图来查询某一时刻的空房信息。
*/

/*系统功能结构
客房信息管理：对客房的信息进行管理，可以增加客房，更新客房的入住情况，修改价格，折扣
客户信息管理：对客户的信息进行管理，实现客户的基本信息登记，包括姓名，身份证号码，年龄，性别。可以记录客户入住时间，退房时间，入住房间号，居住时间。
入住管理：对客户的入住操作进行管理，入住记录包括客人id，房间id，入住时间，操作员姓名，每次入住操作都将在入住管理中产生记录。
退房管理：对客户的退房操作进行管理，退房记录包括客人id，房间id，退房时间，操作员姓名，每次退房操作都将在退房管理中产生记录。
费用管理：对资金的出入进行管理，费用记录包括客人id，押金，房费，操作时间，操作员姓名，备注。客户入住时需要交纳规定的房费和相应的押金，原则上退房时会将押金全数退还，每次资金的出入都会在费用管理里产生记录。
*/

/*数据流图
你们来吧
软件工程的书里有数据流图的内容。
可以参考百度文库这篇文章的第三页
http://wenku.baidu.com/view/31e67706e87101f69e3195a0.html?re=view

我们的数据库是没有预定功能的。
*/

/*数据字典
E－R图转成关系模型
客房表（客房id，房间类型，房间状态，房间价格，房间折扣）主键：房间id
客户表（客户id，客户姓名，客户性别，客户年龄，客户身份证号，居住天数，入住时间，入住房间id，退房时间）主键：客户id 
外键：房间id
入住表（客户id，房间id，入住时间，操作员姓名） 主键：客户id 外键：客户id，房间id
退房表（客户id，房间id，退房时间，操作员姓名） 主键：客户id 外键：客户id，房间id
费用管理表（客户id，押金，房费，记录时的时间，操作员姓名，备注） 主键：客户id 外键：客户id
*/

/*数据库结构
是表格。
*/

/*物理结构设计

*/
#房间表
create table Room
(
	Rid char(5) primary key,     # 房间id
	Rtype char(5) not null,      # 房间类型
	Rstats char(1) not null,     # 房间状态，满或空
	Rprice double(5,2) not null, # 价格
	Rdiscount float(1) default 1 # 折扣,0到1之间的浮点数
);

#插入房间的测试数据
insert into Room values("1001","单人间", "空", 199, 0.8);
insert into Room values("1002","双人间", "空", 299, 1);
insert into Room values("1003","大床房", "空", 299, 1);
insert into Room values("1004","套间", "空", 399, 1);

#客人表
create table Customer
(
	Cid int(4) primary key,               # 客户id
	Cname char(8) not null,               # 姓名
	Csex char(2),                         # 性别
	Cage smallint,                        # 年龄
	Cpnum char(19) unique,                # 身份证号
	Cday smallint,                        # 居住天数
	Cintime datetime,                     # 入住时间
	Rid char(5),                          # 房间id
	Couttime datetime,                    # 退房时间
	foreign key(Rid) references Room(Rid) # 设置外码（外键）
	#以下两行设置完整性约束
	on delete cascade
	on update cascade
);

#入住表
create table Inroom
(
	Cid int(4) primary key, # 客人id
	Rid char(5),            # 房间id
	Itime datetime,         # 入住时间
	Ioperator char(5),      # 操作员姓名
	foreign key(Cid) references Customer(Cid)
	on delete cascade
	on update cascade,
	foreign key(Rid) references Room(Rid)
	on delete cascade
	on update cascade
);

#退房表
create table Outroom
(
	Cid int(4) primary key, # 客人id
	Rid char(5),            # 房间id
	Otime datetime,         # 退房时间
	Ooperator char(5),      # 操作员姓名
	foreign key(Cid) references Customer(Cid)
	on delete cascade
	on update cascade,
	foreign key(Rid) references Room(Rid)
	on delete cascade
	on update cascade
);

#费用管理表
create table Sale
(
	Cid int(4) primary key, # 客人id
	Sdeposit double(5,2),   # 押金
	Scost double(5,2),      # 房费
	Stime datetime,         # 记录时的时间
	Ooperator char(5),      # 操作员姓名
	Smark char(10),         # 备注
	foreign key(Cid) references Customer(Cid)
	on delete cascade
	on update cascade
);

/*
*入住触发器
*当有用户入住时
*在房间表中，将所入住的房间设为满
*在入住表中，插入一条记录
*在费用管理中，插入一条记录
*/
delimiter |
create trigger Insert_Customer
after insert on Customer 
for each row
	begin
	update Room set Rstats="满" where Rid=new.Rid;
	insert into Inroom values(new.Cid, new.Rid, new.Cintime, null);
	insert into Sale values(new.Cid, 200, new.Cday*(select Rprice*Rdiscount from Room where Rid=new.Rid), new.Cintime, null, null);
	end;|
delimiter ;

/*
*退房触发器
*在房间表中，将房间状态设为空
*在退房表中，插入一条记录
*在费用表中，更新记录（将押金退还)
*/
delimiter |
create trigger Out_Customer
after update on Customer
for each row
	begin
		if new.Couttime is not null then
			update Room set Rstats="空" where Rid=new.Rid;
			insert into Outroom values(new.Cid, new.Rid, new.Couttime, null);
			update Sale set Sdeposit = 0 where Cid=new.Cid;
		end if;
	end;|
delimiter ;

#插入客人数据
insert into Customer values(1,"傅", "男", 22, "1234567890123456789", 
	1,"2014-11-09 23:22:11", "1001", null);
insert into Customer values(2,"隆", "男", 22, "1234567890123456781", 
	1,"2014-11-09 23:22:11", "1002", null);
insert into Customer values(3,"亮", "男", 22, "1234567890123456783", 
	1,"2014-11-09 23:22:11", "1002", null);
	
/*
*设置客人退房时间,进行退房操作
*测试退房触发器
*/
update Customer set Couttime ="2014-11-10 12:12:12" where Cid=1;
#update Customer set Couttime ="2014-11-10 12:12:12" where Cid=2;
#update Customer set Couttime ="2014-11-10 12:12:12" where Cid=3;

/*
*储存过程
*统计指定时间端内，不同类型房间的入住时间和费用合计
*/
delimiter |
create procedure Statistic(stime datetime, etime datetime)
begin
	declare ptime datetime;
	select "单人间",sum(Cday),sum(Scost) from Customer,Outroom,Sale 
	where Customer.Cid=Outroom.Cid=Sale.Cid and unix_timestamp(Customer.Cintime) > unix_timestamp(stime) and unix_timestamp(Customer.Couttime) < unix_timestamp(etime) and (select Rtype from Room where Rid = Outroom.Rid)="单人间";
	select "双人间",sum(Cday),sum(Scost) from Customer,Outroom,Sale
	where Customer.Cid=Outroom.Cid and Outroom.Cid=Sale.Cid and unix_timestamp(Customer.Cintime) > unix_timestamp(stime) and unix_timestamp(Customer.Couttime) < unix_timestamp(etime) and (select Rtype from Room where Rid = Outroom.Rid)="双人间";

	select "大床房",sum(Cday),sum(Scost) from Customer,Outroom,Sale
	where Customer.Cid=Outroom.Cid and Outroom.Cid=Sale.Cid and unix_timestamp(Customer.Cintime) > unix_timestamp(stime) and unix_timestamp(Customer.Couttime) < unix_timestamp(etime) and (select Rtype from Room where Rid = Outroom.Rid)="大床房";

	select "套间",sum(Cday),sum(Scost) from Customer,Outroom,Sale
	where Customer.Cid=Outroom.Cid and Outroom.Cid=Sale.Cid and unix_timestamp(Customer.Cintime) > unix_timestamp(stime) and unix_timestamp(Customer.Couttime) < unix_timestamp(etime) and (select Rtype from Room where Rid = Outroom.Rid)="套间";
end;|
delimiter ;

#调用储存过程
call Statistic("2014-10-01 01:00:00", "2014-12-14 12:12:12");

/*
*视图
*空房的信息
*/
create view Empty_Room 
as select Room.Rid, Rtype, Rstats, Rprice, Rdiscount 
from Room
where Rstats="空" ;
