CREATE DEFINER=`root`@`localhost` FUNCTION `get_qtr`(
calender_date date
)
RETURNS CHAR(2)
    DETERMINISTIC
BEGIN
DECLARE m TINYINT;
DECLARE qtr CHAR(2);
SET m = month(calender_date);
 if m in(9,10,11) then
 set qtr = "Q1" ;
 elseif m in(12,1,2) then
 set qtr = "Q2" ;
 elseif m in(3,4,5) then
 set qtr = "Q3" ;
ELSE
set qtr = "Q4" ;
END IF;
RETURN qtr;
END;