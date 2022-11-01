exec logs.create_trigger 'dbo' , 'goods', 1
go

exec logs.create_trigger 'dbo', 'GOODS_CODE' ,1
go 


select *  from GOODS
where id_goods in ( 77,98)
go

delete from goods 
where id_goods in ( 77,98)
go

select * from goods 
where ID_GOODS = 111
go

update goods 
set [name] = 'Измененное имя'
where ID_GOODS = 111
go

select * from goods 
where ID_GOODS = 111
go


delete from goods 
where ID_GOODS in (select top 5 id_goods from GOODS)

INSERT [dbo].[GOODS_CODE] ([ID_GOODS_CODE], [ID_CONTRACTOR], [ID_GOODS], [CODE], [DATE_DELETED], [ID_ES_SUPPLIER_CODE_GLOBAL], [PACKAGE_SIZE]) VALUES (9997, 2389, 164869, N'030030094-00000743', NULL, NULL, NULL)
INSERT [dbo].[GOODS_CODE] ([ID_GOODS_CODE], [ID_CONTRACTOR], [ID_GOODS], [CODE], [DATE_DELETED], [ID_ES_SUPPLIER_CODE_GLOBAL], [PACKAGE_SIZE]) VALUES (9996, 2389, 164692, N'030033929-03001490', NULL, NULL, NULL)


select * from logs.TableLoggingData
order by id

delete from GOODS_CODE
where ID_GOODS_CODE = 9997

select * from GOODS_CODE
where ID_GOODS_CODE = 9997



