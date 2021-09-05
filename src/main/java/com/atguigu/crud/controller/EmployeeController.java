package com.atguigu.crud.controller;

import com.atguigu.crud.bean.Employee;
import com.atguigu.crud.bean.Msg;
import com.atguigu.crud.service.EmployeeService;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * @author lowen
 * @date 2021-09-02 12:40
 */
@Controller
public class EmployeeController {

    @Autowired
    EmployeeService employeeService;

    /**
     * 查询所有员工，并分页显示
     * 导入jackson包，使用JSON返回结果
     * @param pn
     * @return
     */
    @RequestMapping("/emps")
    @ResponseBody
    public Msg getEmpsWithJson(@RequestParam(value = "pn", defaultValue = "1") Integer pn) {
        //引用分页插件工具
        PageHelper.startPage(pn, 5);

        List<Employee> emps = employeeService.getAll();
        //分页信息
        PageInfo<Employee> pageInfo = new PageInfo<>(emps, 5);
        //返回
        return Msg.success().add("pageInfo", pageInfo);
    }
    @RequestMapping("/checkusername")
    @ResponseBody
    public Msg checkUserName(@RequestParam("empName")String empName){
        //先判断用户名是否合法
        String regx = "(^[a-zA-Z0-9_-]{6,16}$)|(^[\\u2E80-\\u9FFF]{2,5})";
        if (! empName.matches(regx)){
            return Msg.fail().add("va_msg", "用户名必须是2-5位中文或者6-16位数字英文的组合");
        }
        boolean b = employeeService.checkUserName(empName);

        if (b) {
            return Msg.success();
        }else {
            return Msg.fail().add("va_msg", "用户名已存在");
        }
    }

    @RequestMapping(value = "/emp", method = RequestMethod.POST)
    @ResponseBody
    public Msg addEmp(@Valid Employee employee, BindingResult result){
        System.out.println(result.hasErrors());
        if (result.hasErrors()){
            HashMap<String, Object> map = new HashMap<>();

            List<FieldError> fieldErrors = result.getFieldErrors();

            for (FieldError fieldError: fieldErrors) {
                System.out.println("错误的字段名：" + fieldError.getField());
                System.out.println("错误信息：" + fieldError.getDefaultMessage());
                map.put(fieldError.getField(), fieldError.getDefaultMessage());
            }
            return Msg.fail().add("errorsFields", map);
        }else {
            employeeService.addEmp(employee);
            return Msg.success();
        }

    }

    /**
     * 查询员工
     * @param id
     * @return
     */
    @RequestMapping(value = "/emp/{id}", method = RequestMethod.GET)
    @ResponseBody
    public Msg getEmp(@PathVariable("id") Integer id) {
        Employee emp = employeeService.getEmp(id);

        return Msg.success().add("emp",emp);
    }

    /**
     * 更新员工信息
     * @param employee
     * @param request
     * @return
     */
    @RequestMapping(value = "/emp/{empId}", method = RequestMethod.PUT)
    @ResponseBody
    public Msg updatEmp(Employee employee, HttpServletRequest request) {
        System.out.println("请求体中的值：" + request.getParameter("gender"));
        System.out.println("将要更新的员工数据" + employee);
        employeeService.updateEmp(employee);
        return Msg.success();
    }

    /**
     * 删除员工
     * @param empId
     * @return
     */
    @RequestMapping(value = "/emp/{empId}", method = RequestMethod.DELETE)
    @ResponseBody
    public Msg deleteEmp(@PathVariable("empId") String empId) {
        if(empId.contains("-")) {
            ArrayList<Integer> ids = new ArrayList<>();
            String[] str_ids = empId.split("-");
            for (String str_id : str_ids) {
                ids.add(Integer.parseInt(str_id));
            }
            employeeService.deleteEmpBatch(ids);
        }else {
            int id = Integer.parseInt(empId);
            employeeService.deleteEmp(id);
        }
        return Msg.success();
    }


    /**
     * 查询所有员工并分页显示
     * @param pn
     * @param model
     * @return
     */
  /*@RequestMapping("/emps")
    public String getEmps(@RequestParam(value = "pn", defaultValue = "1")Integer pn, Model model) {
        //引用分页插件工具
        PageHelper.startPage(pn, 5);

        List<Employee> emps = employeeService.getAll();
        //分页信息
        PageInfo<Employee> pageInfo = new PageInfo<>(emps, 5);

        model.addAttribute("pageInfo", pageInfo);

        return "list";
    }*/
}
