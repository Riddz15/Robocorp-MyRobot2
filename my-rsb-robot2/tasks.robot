*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
${screenshot_dir}       ${OUTPUT_DIR}${/}Screenshots
${receipt_dir}          ${OUTPUT_DIR}${/}Receipts


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the orders CSV file
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Wait Until Element Is Visible    id:order
        Wait Until Keyword Succeeds    10x    2 sec    Submit Order
        ${pdf}=    Export the receipt as a PDF    ${order}[Order number]
        ${screenshot}=    Screenshot of robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order next robot
    END
    Create ZIP file of all receipts
    [Teardown]    Close the Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the orders CSV file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get orders
    ${orders}=    Read table from CSV    orders.csv    header=${True}
    RETURN    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    class:form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    preview

Submit Order
    Click Button    order
    Wait Until Page Contains Element    id:receipt

Export the receipt as a PDF
    [Arguments]    ${order_number}
    ${get_reciept}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${get_reciept}    ${receipt_dir}${/}reciept_${order_number}.pdf
    RETURN    ${receipt_dir}${/}reciept_${order_number}.pdf

Screenshot of robot
    [Arguments]    ${order_number}
    ${png}=    Screenshot    id:robot-preview-image    ${screenshot_dir}${/}robot_${order_number}.png
    RETURN    ${png}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List    ${screenshot}:align=center
    Add Files To Pdf    ${files}    ${pdf}    append:true
    Close Pdf    ${pdf}

Order next robot
    Click Button    order-another

Create ZIP file of all receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip    ${receipt_dir}    ${zip_file_name}

Close the Browser
    Close Browser
