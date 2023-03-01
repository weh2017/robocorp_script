*** Settings ***
Documentation       Order robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the orders robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.FileSystem
Library    RPA.PDF
Library    RPA.Tables
Library    RPA.Windows
Library    RPA.Archive
Suite Setup        Open The Robot Order Website
Suite Teardown     Close Browser
*** Variables ***
${URL}    https://robotsparebinindustries.com/#/robot-order
${CSV_ORDER}    https://robotsparebinindustries.com/orders.csv
${HEADER}       //h2[normalize-space()='Build and order your robot!']
${BTN_OK}        //button[@class='btn btn-dark']
${HEAD}          id:head
${LEGS_OPTION}    //div[3][@class="form-group"]//input[@class="form-control"]
${ADDRESS_OPTION}    id:address
${PREVIEW_BTN}    id:preview
${ORDER_BTN}        id:order
${RECEIPT_RESULT}    id:receipt
${HTML_CONTENT}      <div id="receipt" class="alert alert-success" role="alert"><h3>Receipt</h3><div>2023-02-09T05:26:45.810Z</div><p class="badge badge-success">RSB-ROBO-ORDER-ZM7P39WSFD</p><p>aDDRESS</p><div id="parts" class="alert alert-light" role="alert"><div>Head: 1</div><div>Body: 1</div><div>Legs: 3</div></div><p>Thank you for your order! We will ship your robot to you as soon as our warehouse robots gather the parts you ordered! You will receive your robot in no time!</p></div>
${ROBOT_RESULT}    id:robot-preview-image
${ORDER_ANOTHER}    id:order-another
*** Tasks ***
Order robots from RobotSpareBin Industries Inc

    Get Orders
    Create New Folder And Move File To New Folder
    Archive The PDF File To ZIP


*** Keywords ***
Open The Robot Order Website
    Open Chrome Browser    ${URL}
Get Orders
    # [Arguments]    ${csv}  
    Download    ${CSV_ORDER}    target_file=${CURDIR}   
    ${read}    Read table from CSV    ${CURDIR}${/}orders.csv
    Log To Console     \n${read}
    ${row}  ${columns}    Get Table Dimensions    ${read}
    Log To Console   Table has ${row} rows and ${columns} columns
    ${table_column}    Get Table Column    ${read}    Order number

    FOR  ${table}    IN    @{table_column}
        ${eval}    Evaluate    ${table} - 1
        ${row}  Get Table Row    ${read}    ${eval}    as_list=${True}
        Log To Console    ${table} ${row}
        Close The Annoying Modal
        Select From List By Index    ${HEAD}    ${row}[1]   
        Log To Console  ${row}[1]
        # RETURN    ${table}

        #BODY SECTION
        Input Body    ${row}[2]
        Log To Console     BODY IS ${row}[2]

        #LEGS SECTION
        Input Legs    ${row}[3]
        Log To Console  LEGS IS ${row}[3]

        #ADDRESS OPTION
        Input Address    ${row}[4]
        Log To Console    ${row}[4]

        # PREVIEW
        Preview The Order

        # SUBMIT
        Submit The Order
        Store the receipt as a PDF file  ${row}[4]  ${row}[4]
        Select Order Another Robot
        Sleep  2
    END
Move CSV file
    ${lists}    Create List      log     output.xml     report

    FOR   ${list}        IN   @{lists}
        ${files}        Find Files      ${list}
        Move Files    ${files}    ${CURDIR}    overwrite=True
    END


Read CSV File

    ${csv}   Read table from CSV    ${CURDIR}${/}orders.csv     header=True 

    FOR  ${table}    IN  @{csv}    
        Read Orders    ${table}
    END

Read Orders
    [Arguments]    ${orders}
    Log To Console     \n${orders}[Order number]
    Log To Console     ${orders}[Head]
    Log To Console     ${orders}[Body]
    Log To Console     ${orders}[Legs]
    Log To Console     ${orders}[Address]

Close The Annoying Modal
    [Documentation]    Close the prompt on the screen
    Reload Page
    Sleep  3
    Wait Until Element Is Visible    ${BTN_OK}    timeout=10
    Click Element    ${BTN_OK}
    Page Should Contain    Build and order your robot!

Input Body
    [Arguments]        ${value}
        # ${radio_btn}    Get Element    id=id-body-1
    Select Radio Button    body    id-body-${value}

Input Legs
    [Arguments]    ${index}
    Set Library Search Order  RPA.Browser.Selenium
    Input Text    ${LEGS_OPTION}    ${index}

    ${text}  Get Value    ${LEGS_OPTION}
    Should Be Equal   ${text}   ${index}

Input Address
    [Arguments]    ${adr}
    Set Library Search Order    RPA.Browser.Selenium
    Input Text    ${ADDRESS_OPTION}    ${adr}
    ${text}    Get Value    ${ADDRESS_OPTION}
    Should Be Equal    ${text}   ${adr}

Preview The Order
    Click Element    ${PREVIEW_BTN}
    Sleep  2

Submit The Order
    Sleep  2
    Click Element    ${ORDER_BTN}
    Sleep  2

Store the receipt as a PDF file
    [Arguments]    ${receipt_image}  ${robot_image}
    Sleep  2
    ${count}    Get Element Count    ${RECEIPT_RESULT}
    IF    ${count} == 1
        Wait Until Element Is Visible    ${RECEIPT_RESULT}    timeout=30
        Screenshot   ${RECEIPT_RESULT}    ${OUTPUT_DIR}${/}${receipt_image}_receipt.png
        Screenshot    ${ROBOT_RESULT}    ${OUTPUT_DIR}${/}${robot_image}.png
        ${files}    Create List
        ...        ${OUTPUT_DIR}${/}${receipt_image}_receipt.png:align=center
        ...        ${OUTPUT_DIR}${/}${robot_image}.png:align=center
        Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}rpa_cert.pdf    append=${True}
    END

Embed Screenshots To PDF
        [Arguments]     ${receipt_image}  ${robot_image}
        ${exists_receipt}    Does File Exist    ${OUTPUT_DIR}${/}${receipt_image}_receipt.png
        ${exist_robot}       Does File Exist    ${OUTPUT_DIR}${/}${robot_image}.png
        
        IF    ${exists_receipt} == 1 and ${exist_robot} == 1
                    ${files}    Create List
            ...        ${OUTPUT_DIR}${/}${receipt_image}_receipt.png:align=center
            ...        ${OUTPUT_DIR}${/}${robot_image}.png:align=center
            Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}rpa_cert.pdf
            Open Pdf    ${OUTPUT_DIR}${/}rpa_cert.pdf
            Sleep  2
            Close Pdf            
        END
Select Order Another Robot
    ${count}    Get Element Count  ${ORDER_ANOTHER}
    IF    ${count} == 1
        Click Element   ${ORDER_ANOTHER}
    ELSE
        Log    No Order Another button appears
    END


Create New Folder And Move File To New Folder
    Create Directory    ${OUTPUT_DIR}${/}for_zip
    ${directory_empty}    Is Directory Empty    ${OUTPUT_DIR}${/}for_zip

    ${find}    Find Files    ${OUTPUT_DIR}${/}rpa_cert.pdf
    IF  ${directory_empty}
        Move Files    ${find}    ${OUTPUT_DIR}${/}for_zip    ${True}
    END

Archive The PDF File To ZIP
    Archive Folder With Zip    ${OUTPUT_DIR}${/}for_zip    ${OUTPUT_DIR}${/}for_zip${/}archived_file
