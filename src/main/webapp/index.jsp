<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%--
  Created by IntelliJ IDEA.
  User: 65129
  Date: 2021/9/2
  Time: 11:24
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <title>员工列表</title>
    <%
        pageContext.setAttribute("APP_PATH", request.getContextPath());
    %>
    <script type="text/javascript" src="${APP_PATH}/static/js/jquery-3.5.1.min.js"></script>
    <link rel="stylesheet" href="${APP_PATH}/static/bootstrap-5.0.2-dist/css/bootstrap.min.css"/>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.5.0/font/bootstrap-icons.css">
    <script src="${APP_PATH}/static/bootstrap-5.0.2-dist/js/bootstrap.min.js"></script>
    <script type="text/javascript">
        //定义总记录数和当前页数，用于某些判断
        var totalRecord, currentPage;
        // 1.页面加载完成以后，直接发送ajax请求，到分页数据
        $(function () {
            //页面开始首页
            toPage(1);

            //创建模态框变量
            var empAddModal = new bootstrap.Modal(document.getElementById('empAddModal'), {
                backdrop: "static"
            });
            var empUpdateModal = new bootstrap.Modal(document.getElementById('empUpdateModal'), {
                backdrop: "static"
            });

            //添加员工
            //点击新增按钮弹出"添加员工"模态框
            $("#emp_add_modal_btn").click(function () {
                //清除表单：内容、样式
                $("#empAddModal form")[0].reset();
                $("#empAddModal form").find("*").removeClass("is-valid is-invalid");
                //发送ajax请求，查出部门信息，显示在下拉列表中
                getDepts("#empAddModal select");
                //弹出模态框
                empAddModal.show();
            });

            //点击保存，保存员工到数据库
            $("#emp_save_btn").click(function () {
                //1.将员工添加的模态框添加到数据库，首先对提交数据进行验证
                //2.前端表单数据正则表达式验证
                if(!validateAddForm()){
                    return false;
                }
                //3.用户名是否可用
                if($("this").attr("isUsableName") == "error"){
                    return false;
                }
                //4.发送ajax请求保存员工
                alert($("#empAddModal form").serialize());
                $.ajax({
                    url: "${APP_PATH}/emp",
                    type: "POST",
                    data: $("#empAddModal form").serialize(),
                    success: function (result){
                        alert(result.code);
                        if (result.code == 100) {
                            //员工保存成功
                            //1.关闭模态框
                            empAddModal.hide();
                            //2.显示员工最后一页
                            toPage(totalRecord);
                        }else {
                            alert(result.extend.errorsFields.empName);
                            console.log(result);
                            if(undefined != result.extend.errorsFields.email) {
                                //显示邮箱错误信息
                                showValidateMsg("#inputEmail", "error", result.extend.errorsFields.email);
                            }
                            if(undefined != result.extend.errorsFields.empName) {
                                //显示邮箱错误信息
                                showValidateMsg("#inputLastName", "error", result.extend.errorsFields.empName);
                            }

                        }
                    }
                })
            });

            //从数据库查询用户名是否可用
            $("#inputLastName").change(function (){
                //发送ajax请求校验用户名是否可用
                var empName = this.value;
                // alert(empName);
                $.ajax({
                    url: "${APP_PATH}/checkusername",
                    data: "empName="+empName,
                    type: "POST",
                    success: function (result) {
                        // alert(result.code);
                        if (result.code == 100) {
                            showValidateMsg("#inputLastName", "success", "用户名可用");
                            $("#emp_save_btn").attr("isUsableName", "success");
                        }else {
                            showValidateMsg("#inputLastName", "error", result.extend.va_msg);
                            $("#emp_save_btn").attr("isUsableName", "error");
                        }
                    }
                })
            });
            //修改员工
            //编辑按钮绑定事件
            $(document).on("click", ".edit_btn", function (){
                //1.查出部门信息，显示在部门列表
                getDepts("#empUpdateModal select");
                //2.查出员工信息，显示在模态框
                getEmp($(this).attr("edit-id"));
                //3.把员工id传递给模态的更新按钮
                $("#emp_update_btn").attr("edit-id", $(this).attr("edit-id"));
                empUpdateModal.show();
            });

            /*    $(".edit_btn").click(function(){
                    //1.查出部门信息，显示在部门列表
                    getDepts("#empUpdateModal select");
                    //2.查出员工信息，显示在模态框
                    getEmp($(this).attr("edit-id"));
                    //3.把员工id传递给模态的更新按钮
                    $("#emp_update_btn").attr("edit-id", $(this).attr("edit-id"));
                    empUpdateModal.show();
                });*/
            //点击更新，更新员工数据
            $("#emp_update_btn").click(function (){
                //验证邮箱是否合法
                //1、校验邮箱信息
                var email = $("#updateEmail").val();
                var regEmail = /^([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})$/;
                if(!regEmail.test(email)){
                    showValidateMsg("#updateEmail", "error", "邮箱格式不正确");
                    return false;
                }else{
                    showValidateMsg("#updateEmail", "success", "");
                }

                //2、发送ajax请求保存更新的员工数据
                $.ajax({
                    url: "${APP_PATH}/emp/"+$(this).attr("edit-id"),
                    type: "PUT",
                    data: $("#empUpdateModal form").serialize(),
                    success: function(result){
                        //alert(result.msg);
                        //1、关闭对话框
                        empUpdateModal.hide();
                        //2、回到本页面
                        to_page(currentPage);
                    }
                });
            });
            //删除单个员工
            $(document).on("click",".delete_btn",function(){
                //1、弹出是否确认删除对话框
                var empName = $(this).parents("tr").find("td:eq(2)").text();
                var empId = $(this).attr("delete-id");
                //alert($(this).parents("tr").find("td:eq(1)").text());
                if(confirm("确认删除【"+empName+"】吗？")){
                    //确认，发送ajax请求删除即可
                    $.ajax({
                        url:"${APP_PATH}/emp/"+empId,
                        type:"DELETE",
                        success:function(result){
                            alert(result.msg);
                            //回到本页
                            to_page(currentPage);
                        }
                    });
                }
            });
            //完成全选/全不选功能
            $("#check_all").click(function(){
                //attr获取checked是undefined;
                //我们这些dom原生的属性；attr获取自定义属性的值；
                //prop修改和读取dom原生属性的值
                $(".check_item").prop("checked",$(this).prop("checked"));
            });
            //check_item
            $(document).on("click",".check_item",function(){
                //判断当前选择中的元素是否5个
                var flag = $(".check_item:checked").length==$(".check_item").length;
                $("#check_all").prop("checked",flag);
            });

            //点击全部删除，就批量删除
            $("#emp_delete_all_btn").click(function(){
                //
                var empNames = "";
                var del_idstr = "";
                $.each($(".check_item:checked"),function(){
                    //this
                    empNames += $(this).parents("tr").find("td:eq(2)").text()+",";
                    //组装员工id字符串
                    del_idstr += $(this).parents("tr").find("td:eq(1)").text()+"-";
                });
                //去除empNames多余的 ,
                empNames = empNames.substring(0, empNames.length-1);
                //去除删除的id多余的 -
                del_idstr = del_idstr.substring(0, del_idstr.length-1);
                if(confirm("确认删除【"+empNames+"】吗？")){
                    //发送ajax请求删除
                    $.ajax({
                        url:"${APP_PATH}/emp/"+del_idstr,
                        type:"DELETE",
                        success:function(result){
                            alert(result.msg);
                            //回到当前页面
                            to_page(currentPage);
                        }
                    });
                }
            });

        });

        //根据ID查出员工信息
        function getEmp(id) {
            $.ajax({
                url: "${APP_PATH}/emp/" + id,
                type: "GET",
                success: function (result) {
                    var emp = result.extend.emp;
                    $("#staticEmpName").val(emp.empName);
                    $("#updateEmail").val(emp.email);
                    $("#empUpdateModal input[name=gender]").val([emp.gender]);
                    $("#empUpdateModal select").val([emp.dId]);
                }
            })
        }
        //表单正则验证
        function validateAddForm() {
            //用户名输入验证
            var empName = $("#inputLastName").val();
            var regName = /(^[a-zA-Z0-9_-]{6,16}$)|(^[\u2E80-\u9FFF]{2,5})/;
            if (!regName.test(empName)) {
                showValidateMsg("#inputLastName", "error", "用户名为2-5位的中文名或者6-16位的英文数字组合");
                return false;
            }else {
                showValidateMsg("#inputLastName", "success", "");
            }
            //邮箱输入验证
            var email = $("#inputEmail").val();
            var regEmail = /^([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})$/;
            if (!regEmail.test(email)) {
                showValidateMsg("#inputEmail", "error", "邮箱格式不正确");
                return false;
            }else {
                showValidateMsg("#inputEmail", "success", "");
            }
            return true;
        }

        //显示校验结果的提示信息
        function showValidateMsg(ele, status, msg) {
            //清除当前元素的校验状态
            $(ele).removeClass("form-control is-invalid is-valid");
            $(ele).next("div").removeClass("invalid-feedback valid-feedback");
            $(ele).next("div").text("");
            if ("success" == status) {
                $(ele).addClass("form-control is-valid");
                $(ele).next("div").addClass("valid-feedback");
                $(ele).next("div").text(msg);
            } else if ("error" == status) {
                // alert("false");
                $(ele).addClass("form-control is-invalid");
                $(ele).next("div").addClass("invalid-feedback");
                $(ele).next("div").text(msg);
            }
        }

        function toPage(pn) {
            $.ajax({
                url: "${APP_PATH}/emps",
                data: "pn=" + pn,
                type: "GET",
                success: function (result) {
                    console.log(result);
                    //1.解析并显示员工数据
                    bulidEmpsTable(result);
                    //2.解析并并显示分页信息
                    bulidPageInfo(result);
                    //3.解析并显示分页数据条
                    bulidPageNav(result);
                }
            });
        }
        //查出所有的部门信息并显示在下拉列表中
        function  getDepts(ele) {
            //清空之前下拉列表的值
            $(ele).empty();
            //发送ajax请求
            $.ajax({
                url: "${APP_PATH}/depts",
                type: "GET",
                success: function (result){
                    $.each(result.extend.depts, function (){
                        var optionEle = $("<option></option>").append(this.deptName).attr("value", this.deptId);
                        optionEle.appendTo(ele);
                    });
                }
            })
        }


        //解析显示员工信息表格
        function bulidEmpsTable(result) {
            //清空table表格
            $("#emps_table tbody").empty();
            //获取某页员工信息
            var emps = result.extend.pageInfo.list;
            //循环遍历显示每一条员工信息
            $.each(emps, function (index, item) {
                var checkBoxTd = $("<td><input type='checkbox' class='check_item'/></td>");
                var empIdTd = $("<td></td>").attr("scope", "row").append(item.empId);
                var empNameTd = $("<td></td>").append(item.empName);
                var genderTd = $("<td></td>").append(item.gender == "M" ? "男" : "女");
                var emailTd = $("<td></td>").append(item.email);
                var deptNameTd = $("<td></td>").append(item.dept.deptName);
                var editBtn = $("<button></button>").addClass("btn btn-primary btn-sm edit_btn").append($("<i></i>").addClass("bi bi-pencil")).append("编辑");
                //为编辑按钮添加一个自定义的属性，表示当前员工的id
                editBtn.attr("edit-id", item.empId);
                var deleteBtn = $("<button></button>").addClass("btn btn-danger btn-sm delete_btn").append($("<i></i>").addClass("bi bi-trash")).append("删除");
                deleteBtn.attr("delete-id", item.empId);
                var btnTd = $("<td></td>").append(editBtn).append("").append(deleteBtn);
                //添加所有标签到tbody中
                $("<tr></tr>").append(checkBoxTd).append(empIdTd).append(empNameTd).append(emailTd).append(genderTd).append(deptNameTd).append(btnTd)
                    .appendTo("#emps_table tbody");
            });
        }

        //解析显示分页信息
        function bulidPageInfo(result) {
            //清空分页信息
            $("#page_info_area").empty();
            $("#page_info_area").append("当前第" + result.extend.pageInfo.pageNum + "页，共" +
                result.extend.pageInfo.pages + "页，共" +
                result.extend.pageInfo.total + "条记录")
            totalRecord = result.extend.pageInfo.total;
            currentPage = result.extend.pageInfo.pageNum;
        }

        //解析显示分页导航
        function bulidPageNav(result) {
            //清空分页导航条
            $("#page_nav_area").empty();
            //创建列表
            var ul = $("<ul></ul>").addClass("pagination");
            //构建表中元素
            //首页、前一页
            var firstPageLi = $("<li></li>").addClass("page-item").append($("<a></a>").addClass("page-link").append("首页").attr("href", "#"));
            var prePageLi = $("<li></li>").addClass("page-item").append($("<a></a>").addClass("page-link").append("&laquo;"));
            if (result.extend.pageInfo.hasPreviousPage == true) {
                //为元素添加点击翻页事件
                firstPageLi.click(function () {
                    toPage(1);
                });
                prePageLi.click(function () {
                    toPage(result.extend.pageInfo.pageNum - 1);
                });
            } else {
                firstPageLi.removeClass("page-item");
                firstPageLi.addClass("page-item disabled");
                prePageLi.removeClass("page-item");
                prePageLi.addClass("page-item disabled");
            }
            //末页、下一页
            var lastPageLi = $("<li></li>").addClass("page-item").append($("<a></a>").addClass("page-link").append("末页").attr("href", "#"));
            var nextPageLi = $("<li></li>").addClass("page-item").append($("<a></a>").addClass("page-link").append("&raquo;"));
            if (result.extend.pageInfo.hasNextPage == false) {
                lastPageLi.removeClass("page-item");
                lastPageLi.addClass("page-item disabled");
                nextPageLi.removeClass("page-item")
                nextPageLi.addClass("page-item disabled");
            } else {
                //为元素添加点击翻页事件
                lastPageLi.click(function () {
                    toPage(result.extend.pageInfo.pages);
                });
                nextPageLi.click(function () {
                    toPage(result.extend.pageInfo.pageNum + 1);
                });
            }
            //添加首页、前一页到<ul></ul>
            ul.append(firstPageLi).append(prePageLi);
            //遍历添加导航页码
            $.each(result.extend.pageInfo.navigatepageNums, function (index, item) {
                var pageNumli = $("<li></li>").addClass("page-item").append($("<a></a>").addClass("page-link").append(item));
                if (result.extend.pageInfo.pageNum == item) {
                    pageNumli.removeClass("page-item");
                    pageNumli.addClass("page-item active");
                }
                pageNumli.click(function () {
                    toPage(item);
                });
                ul.append(pageNumli);
            })
            //添加下一页、末页
            ul.append(nextPageLi).append(lastPageLi);
            //把ul添加到nav
            var pageNav = $("<nav></nav>").attr("aria-label", "Page navigation").append(ul);
            pageNav.appendTo("#page_nav_area");
        }

    </script>
</head>

<body>
<%--初始显示页面--%>
<div class="container">
    <%--标题--%>
    <div class="row">
        <div class="col-md-12">
            <h1>SSM-CRUD</h1>
        </div>
    </div>
    <%--按钮--%>
    <div class="row">
        <div class="col-md-2 offset-md-10">
            <button type="button" class="btn btn-primary" id="emp_add_modal_btn">新增</button>
            <button type="button" class="btn btn-danger" id="emp_delete_all_btn">删除</button>
        </div>
    </div>
    <%--显示表格数据--%>
    <div class="row">
        <div class="col-md-12">
            <table class="table table-hover" id="emps_table">
                <thead>
                <tr>
                    <th scope="col">
                        <input type="checkbox" id="check_all"/>
                    </th>
                    <th scope="col">id</th>
                    <th scope="col">empName</th>
                    <th scope="col">eamil</th>
                    <th scope="col">gender</th>
                    <th scope="col">deptname</th>
                    <th scope="col">操作</th>
                </tr>
                </thead>
                <tbody>
                </tbody>
            </table>
        </div>
    </div>
    <%--分页信息--%>
    <div class="row">
        <%--分页文字信息--%>
        <div class="col-md-6" id="page_info_area">
        </div>
        <%--分页条信息--%>
        <div class="col-md-4 offset-md-2" id="page_nav_area">
        </div>
    </div>
</div>
<%--新增员工模态框--%>
<div class="modal fade" id="empAddModal" tabindex="-1" aria-labelledby="empAddModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="empAddModalLabel">员工添加</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form class="needs-validation">
                    <div class="row mb-3">
                        <label for="inputLastName" class="col-sm-2 col-form-label">lastName</label>

                        <div class="col-sm-10">
                            <input type="text" name="empName" class="form-control" id="inputLastName" />
                            <div id="inputLastNameFeedback"></div>
                        </div>

                    </div>
                    <div class="row mb-3">
                        <label for="inputEmail" class="col-sm-2 col-form-label">email</label>
                        <div class="col-sm-10">
                            <input type="text" name="email" class="form-control" id="inputEmail">
                            <div id="inputEmailFeedback"></div>
                        </div>

                    </div>
                    <fieldset class="row mb-3">
                        <legend class="col-form-label col-sm-2 pt-0">gender</legend>
                        <div class="col-sm-10">
                            <div class="form-check form-check-inline">
                                <input class="form-check-input" type="radio" name="gender" id="check_gender_m" value="M" checked="checked">
                                <label class="form-check-label" for="check_gender_m">男</label>
                            </div>
                            <div class="form-check form-check-inline">
                                <input class="form-check-input" type="radio" name="gender" id="check_gender_f" value="F">
                                <label class="form-check-label" for="check_gender_f">女</label>
                            </div>
                        </div>
                    </fieldset>
                    <fieldset class="row mb-3">
                        <legend class="col-form-label col-sm-2 pt-0">deptname</legend>
                        <div class="col-sm-5">
                            <%--提交部门id--%>
                            <select name="dId" class="form-select" aria-label="Default select example">
                            </select>
                        </div>
                    </fieldset>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
                <button type="button" class="btn btn-primary" id="emp_save_btn">保存</button>
            </div>
        </div>
    </div>
</div>
<%--员工修改模态框--%>
<div class="modal fade" id="empUpdateModal" tabindex="-1" aria-labelledby="empAddModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="empUpdateModalLabel">员工修改</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form class="needs-validation">
                    <div class="row mb-3">
                        <label for="inputLastName" class="col-sm-2 col-form-label">lastName</label>

                        <div class="col-sm-10">
                            <input type="text" name="empName" readonly class="form-control-plaintext" id="staticEmpName" />
                        </div>
                    </div>
                    <div class="row mb-3">
                        <label for="updateEmail" class="col-sm-2 col-form-label">email</label>
                        <div class="col-sm-10">
                            <input type="text" name="email" class="form-control" id="updateEmail">
                            <div id="updateEmailFeedback"></div>
                        </div>

                    </div>
                    <fieldset class="row mb-3">
                        <legend class="col-form-label col-sm-2 pt-0">gender</legend>
                        <div class="col-sm-10">
                            <div class="form-check form-check-inline">
                                <input class="form-check-input" type="radio" name="gender" id="update_gender_m" value="M" checked="checked">
                                <label class="form-check-label" for="update_gender_m">男</label>
                            </div>
                            <div class="form-check form-check-inline">
                                <input class="form-check-input" type="radio" name="gender" id="update_gender_f" value="F">
                                <label class="form-check-label" for="update_gender_f">女</label>
                            </div>
                        </div>
                    </fieldset>
                    <fieldset class="row mb-3">
                        <legend class="col-form-label col-sm-2 pt-0">deptname</legend>
                        <div class="col-sm-5">
                            <%--提交部门id--%>
                            <select name="dId" class="form-select" aria-label="Default select example">
                            </select>
                        </div>
                    </fieldset>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
                <button type="button" class="btn btn-primary" id="emp_update_btn">更新</button>
            </div>
        </div>
    </div>
</div>
</body>
</html>
