create or replace package log_oracle_job as

  procedure log_starttime(pobj_name varchar2);

  procedure log_endtime(pobj_name varchar2);

  procedure log_exception
    (pobj_name varchar2,perr_message clob);

  procedure execute_proc_if_enabled
    (pobj_name varchar2,plocation_name varchar2);                               

  procedure execute_proc
    (pobj_name varchar2,plocation_name varchar2);
                         

  procedure execute_proc_if_enabled_without_exception_handling
    (pobj_name varchar2,plocation_name varchar2);                            
  
  procedure execute_proc_without_exception_handling(pobj_name varchar2, 
                                                    plocation_name varchar2);  

end log_oracle_job;
/

create or replace package body log_oracle_job as

  --------------------------------------------
  procedure log_starttime(pobj_name varchar2) is
  begin
    insert into tb_log_oracle_jobs
      (start_time, object_name)
    values
      (sysdate, pobj_name);
    commit;
  end;
  --------------------------------------------
  procedure log_endtime(pobj_name varchar2) is
  begin
    update tb_log_oracle_jobs t
       set t.end_time = sysdate
     where t.id = (select max(t1.id)
                     from tb_log_oracle_jobs t1
                    where t1.object_name = pobj_name);
    commit;
  end;
  --------------------------------------------
  procedure log_exception(pobj_name varchar2, perr_message clob) is
  begin
    update tb_log_oracle_jobs t
       set (t.exception_time, t.message) =
           (select sysdate, perr_message from dual)
     where t.id = (select max(t1.id)
                     from tb_log_oracle_jobs t1
                    where t1.object_name = pobj_name);
    commit;
  end;
  --------------------------------------------
  procedure execute_proc_if_enabled(pobj_name      varchar2,
                                   plocation_name varchar2) is
    penable varchar2(50) := 'ENABLE';
  begin
    if eds_basetable.eds_setting.read_setting_by_name(puser_id  => 'SYSTEM',
                                                      pset_name => upper(pobj_name)) =
       penable then
      log_oracle_job.execute_proc(pobj_name      => pobj_name,
                                                     plocation_name => plocation_name);
    end if;
  end;
  --------------------------------------------
  procedure execute_proc(pobj_name varchar2, plocation_name varchar2) is
    vsql          clob;
    error_message clob;
  begin
    begin
      vsql := ' begin ' || plocation_name || pobj_name || '; end;';
      log_oracle_job.log_starttime(pobj_name);
      execute immediate vsql;
      log_oracle_job.log_endtime(pobj_name);
    exception
      when others then
        error_message := sqlerrm;
        log_oracle_job.log_exception(pobj_name    => pobj_name,
                                     perr_message => error_message);
    end;
  end;
  --------------------------------------------      
  procedure execute_proc_if_enabled_without_exception_handling
    (pobj_name varchar2, plocation_name varchar2) is
    penable varchar2(50) := 'ENABLE';
  begin
    if eds_setting.read_setting_by_name
      (puser_id  => 'SYSTEM', pset_name => upper(pobj_name)) = penable 
    then
      log_oracle_job.execute_proc_without_exception_handling
       (pobj_name=> pobj_name, plocation_name => plocation_name);
    end if;
  end;
  --------------------------------------------  
  procedure execute_proc_without_exception_handling
    (pobj_name varchar2, plocation_name varchar2) is
    vsql          clob;
  begin
    vsql := ' begin ' || plocation_name || pobj_name || '; end;';
    log_oracle_job.log_starttime(pobj_name);
    execute immediate vsql;
    log_oracle_job.log_endtime(pobj_name);
  end;
  --------------------------------------------
end log_oracle_job;