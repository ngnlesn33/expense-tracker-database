# expense-tracker-database                    
## What the project does
Cơ sở dữ liệu theo dõi chi phí được thiết kế để nắm bắt các chi tiết khác nhau về từng khoản chi phí, bao gồm ngày tháng, danh mục (chẳng hạn như groceries, transportation, entertainment… v.v.), số tiền đã chi tiêu, phương thức thanh toán và bất kỳ ghi chú hoặc mô tả bổ sung nào. Cơ sở dữ liệu cũng có thể bao gồm thông tin về thu nhập, cho phép có cái nhìn tổng quan toàn diện về dòng tiền tài chính chảy vào và chảy ra. 
## Why the project is useful
Sinh viên thường xuyên gặp khó khăn trong việc quản lý tiền sinh hoạt bố mẹ gửi hàng tháng. Do không thống kê lại các chi tiêu của bản thân, không có chiến lược chi tiêu hợp lý dẫn đến việc chưa hết tháng thì tiền đã hết. Điều đó gây ra rất nhiều khó khăn và biến bản thân thành một con người không có kế hoạch. Cơ sở dữ liệu theo dõi chi phí là một hệ thống được thiết kế để lưu trữ và quản lý thông tin tài chính liên quan đến chi phí. Nó được các cá nhân sử dụng để theo dõi và phân tích mô hình chi tiêu, phân bổ ngân sách và sức khỏe tài chính tổng thể. Cơ sở dữ liệu đóng vai trò là kho lưu trữ trung tâm để ghi lại, tổ chức và truy xuất dữ liệu chi phí, cho phép người dùng giám sát hiệu quả các khoản chi tiêu của họ và đưa ra các quyết định tài chính sáng suốt.
## How users can get started with the project
Download the `expense_tracker_db.sql` file and use pgadmin 4 

## Requirments
1.	Thêm giao dịch mới: Người dùng có thể nhập chi tiết giao dịch của họ vào cơ sở dữ liệu, bao gồm số tiền, ngày, danh mục và phương thức thanh toán. 
2.	Phân loại chi phí: Cơ sở dữ liệu cho phép người dùng chỉ định từng khoản chi phí vào một danh mục cụ thể, giúp phân tích các mô hình chi tiêu và xác định các khoản tiết kiệm tiềm năng dễ dàng hơn. Cảnh báo khi chạm tới mức giới hạn hoặc khi có các chi tiêu bất thường xảy ra.
3.	Tạo báo cáo: Người dùng có thể tạo báo cáo dựa trên các tiêu chí được chỉ định, chẳng hạn như chi phí trong một khoảng thời gian cụ thể, theo danh mục hoặc theo phương thức thanh toán. Các báo cáo này cung cấp thông tin chi tiết về thói quen chi tiêu và giúp lập ngân sách và lập kế hoạch tài chính.
4.	Lập ngân sách và thiết lập mục tiêu: Cơ sở dữ liệu có thể hỗ trợ các tính năng lập ngân sách bằng cách cho phép người dùng đặt giới hạn chi tiêu cho các danh mục khác nhau và theo dõi tiến độ của họ đối với các mục tiêu tài chính.
5.	Phân tích mô hình chi tiêu: Cơ sở dữ liệu theo dõi chi phí cho phép người dùng phân tích mô hình chi tiêu của họ theo thời gian, xác định xu hướng và hiểu rõ hơn về thói quen tài chính của họ.
6.	Tích hợp với các hệ thống khác: Cơ sở dữ liệu theo dõi chi phí có thể được tích hợp với các hệ thống hoặc ứng dụng tài chính khác, chẳng hạn như phần mềm kế toán hoặc ứng dụng dành cho thiết bị di động, để hợp lý hóa việc nhập dữ liệu và đảm bảo tính nhất quán trên các nền tảng.
## Database design
### Entity-Relationship diagram
![erd-expense_tracker drawio](/assets/erd-expense_tracker.drawio.png)
### Table
![er-expense_tracker drawio](/assets/er-expense_tracker.drawio.png)
## Function
**1. Xem tất cả các chi tiêu của bản thân:**  Người dùng có thể xem được tất cả transaction mà người đó đã thêm vào cơ sở dữ liệu từ trước đến hiện tại và không thể xem được của những người khác. Người dùng phải nhập tài khoản và mật khẩu để xác thực. Khi nhập sai tài khoản, mật khẩu hệ thống sẽ thông báo lỗi và chức năng không được thực hiện.

`SELECT * FROM display_all_transactions('JohnDoe', 'password123');`

**2.	Xem các chi tiêu của bản thân trong tháng:**  Người dùng có thể xem được các transaction trong tháng, người dùng nhập tài khoản, mật khẩu, năm và tháng. Người dùng chỉ có thể xem khi nhập đúng tài khoản. Nếu nhập sai hệ thống báo lỗi và chức năng không được thực hiện.

`SELECT * FROM display_all_transactions_month('JohnDoe', 'password123', 2023, 7);`

**3. Thêm thông tin về chi tiêu vào cơ sở dữ liệu:** Người dùng nhập các thông tin bao gồm: tài khoản, mật khẩu, date, amount, category_name, payment_method, notes. Mỗi người dùng sẽ chỉ có thể nhập vào cơ sở dữ liệu của mình khi nhập đúng tài khoản và thông tin sẽ được insert vào bảng transaction, khi nhập sai tài khoản, hay category_name không đúng với category_name đã khai báo trước trong bàng category sẽ thông báo lỗi và chức năng không được thực hiện.

`SELECT insert_transaction('JohnDoe', 'password123', '2023-07-06', 199 , 'Travel', 'Credit Card', 'Dining')`

**4. Thống kê chi tiêu theo danh mục:** Người dùng nhập tài khoản, mật khẩu. Hệ thống sẽ thống kê tất cả chi tiêu của bản thân từ trước đến hiện tại theo category_name. Người dùng chỉ có thể xem khi nhập đúng tài khoản. Nếu nhập sai hệ thống báo lỗi và chức năng không được thực hiện.

`SELECT * FROM display_category_sum('JohnDoe', 'password123');`

**5. Thống kê chi tiêu theo danh mục trong tháng:** Người dùng nhập tài khoản, mật khẩu,năm và tháng. Hệ thống sẽ thống kê tất cả chi tiêu của bản thân trong tháng theo category_name. Người dùng chỉ có thể xem khi nhập đúng tài khoản. Nếu nhập sai hệ thống báo lỗi và chức năng không được thực hiện.

`SELECT * FROM display_category_sum_month('JohnDoe', 'password123', 2023, 2);`

**6. Cập nhật các transaction đã thêm từ trước:** Người dùng có thể cập nhật lại các transaction của bản thân dựa trên transaction_id. Người dùng nhập tài khoản, mật khẩu, transaction_id, date, amount, category_name, payment_method và motes. Người dùng chỉ có thể cập nhật lại khi nhập đúng tài khoản và category_name phải trùng với category_name đã có sẵn trong hệ thống. Nếu nhập sai hệ thống báo lỗi và chức năng không được thực hiện.

`SELECT update_transaction(4, 'JohnDoe', 'password123', '2023-07-01', 150, 3, 'Credit Card',' ');`

**7. Xóa các giao dịch:** Người dùng có thể xóa các transaction của mình dựa trên transaction_id. Người dùng nhập tài khoản, mật khẩu và transaction_id. . Người dùng chỉ có thể xóa khi nhập đúng tài khoản. Nếu nhập sai hệ thống báo lỗi và chức năng không được thực hiện.

`SELECT delete_transaction('JohnDoe', 'password123', 4);`

**8. Cập nhật lại budget:** Người dùng có thể cập nhật lại budget của bản thân cho từng category. Người dùng nhập tài khoản, mật khẩu, budget_name và amount. Người dùng chỉ có thể cập nhật lại khi nhập đúng tài khoản và category_name phải trùng với category_name đã có sẵn trong hệ thống. Nếu nhập sai hệ thống báo lỗi và chức năng không được thực hiện.

`SELECT update_budget_by_category('JohnDoe', 'password123', 'Groceries', 35000);`
