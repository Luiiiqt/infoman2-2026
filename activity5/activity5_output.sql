-- Part 1
select count(*) from students;

-- Part 2
explain analyze select * from students where first_name = 'Tobin';

-- Part 3
create index idx_first_name on students(first_name);

-- Part 4
insert into students (first_name, middle_name, last_name, school_id, course, address)
values ('Luigi', 'Lete', 'Hufana', 2401855, 'IT', 'La Union');