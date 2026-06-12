import os

# Define base directory
base_dir = "force-app/main/default"

def create_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

# 1. Custom Tab Metadata
def generate_tab(object_name, label, motif):
    tab_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<CustomTab xmlns="http://soap.sforce.com/2006/04/metadata">
    <customObject>true</customObject>
    <motif>{motif}</motif>
</CustomTab>"""
    path = f"{base_dir}/tabs"
    create_dir(path)
    with open(f"{path}/{object_name}.tab-meta.xml", "w", encoding="utf-8") as f:
        f.write(tab_xml)

# 2. Custom Object Metadata
def generate_object(object_name, label, plural, name_field_label, name_field_type, sharing_model, auto_num_format=None, search=True, reports=True):
    name_field_xml = ""
    if name_field_type == "AutoNumber":
        name_field_xml = f"""    <nameField>
        <displayFormat>{auto_num_format}</displayFormat>
        <label>{name_field_label}</label>
        <type>AutoNumber</type>
        <startingNumber>1</startingNumber>
    </nameField>"""
    else:
        name_field_xml = f"""    <nameField>
        <label>{name_field_label}</label>
        <type>Text</type>
    </nameField>"""

    obj_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <actionOverrides>
        <actionName>Accept</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>CancelEdit</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Clone</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Delete</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Edit</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>List</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>New</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>SaveEdit</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>Tab</actionName>
        <type>Default</type>
    </actionOverrides>
    <actionOverrides>
        <actionName>View</actionName>
        <type>Default</type>
    </actionOverrides>
    <allowInChatterGroups>false</allowInChatterGroups>
    <compactLayoutAssignment>SYSTEM</compactLayoutAssignment>
    <deploymentStatus>Deployed</deploymentStatus>
    <enableActivities>false</enableActivities>
    <enableBulkApi>true</enableBulkApi>
    <enableLicensing>false</enableLicensing>
    <enableReports>{str(reports).lower()}</enableReports>
    <enableSearch>{str(search).lower()}</enableSearch>
    <enableSharing>true</enableSharing>
    <enableStreamingApi>true</enableStreamingApi>
    <externalSharingModel>{sharing_model}</externalSharingModel>
    <label>{label}</label>
{name_field_xml}
    <pluralLabel>{plural}</pluralLabel>
    <sharingModel>{sharing_model}</sharingModel>
    <visibility>Public</visibility>
</CustomObject>"""
    
    path = f"{base_dir}/objects/{object_name}"
    create_dir(path)
    with open(f"{path}/{object_name}.object-meta.xml", "w", encoding="utf-8") as f:
        f.write(obj_xml)

def generate_field(object_name, field_name, label, field_type, required=False, unique=False, length=None, precision=None, scale=None, related_to=None, picklist_values=None, formula=None):
    type_xml = f"    <type>{field_type}</type>"
    req_xml = f"    <required>{str(required).lower()}</required>" if field_type != "Checkbox" and field_type != "MasterDetail" else ""
    uniq_xml = f"    <unique>{str(unique).lower()}</unique>" if unique and field_type == "Text" else ""
    len_xml = f"    <length>{length}</length>" if length else ""
    prec_scale_xml = f"    <precision>{precision}</precision>\n    <scale>{scale}</scale>" if precision is not None else ""
    
    visible_lines_xml = ""
    if field_type == "LongTextArea":
        visible_lines_xml = "\n    <visibleLines>3</visibleLines>"

    default_val_xml = ""
    if field_type == "Checkbox":
        default_val_xml = "\n    <defaultValue>false</defaultValue>"

    rel_xml = ""
    if field_type in ["Lookup", "MasterDetail"]:
        rel_xml = f"    <referenceTo>{related_to}</referenceTo>\n    <relationshipName>{object_name.replace('__c', '')}s</relationshipName>"
        if field_type == "Lookup":
            rel_xml += "\n    <relationshipLabel>Admissions</relationshipLabel>" if object_name == "Admission__c" else ""
            if required:
                rel_xml += "\n    <deleteConstraint>Restrict</deleteConstraint>"
        elif field_type == "MasterDetail":
            rel_xml += "\n    <writeRequiresMasterRead>false</writeRequiresMasterRead>\n    <reparentableMasterDetail>false</reparentableMasterDetail>"

    pk_xml = ""
    if field_type == "Picklist" and picklist_values:
        val_xmls = []
        for i, val in enumerate(picklist_values):
            def_str = "true" if i == 0 else "false"
            val_xmls.append(f"""            <value>
                <fullName>{val}</fullName>
                <default>{def_str}</default>
                <label>{val}</label>
            </value>""")
        pk_xml = f"""    <valueSet>
        <valueSetDefinition>
            <sorted>false</sorted>
{chr(10).join(val_xmls)}
        </valueSetDefinition>
    </valueSet>"""

    for_xml = ""
    if field_type == "Formula" and formula:
        # For formulas, we need to return formula type and formula string.
        # Let's override type_xml and specify formula
        type_xml = "    <type>Text</type>"
        for_xml = f"    <formula>{formula}</formula>\n    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>"

    field_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>{field_name}</fullName>
    <label>{label}</label>
{type_xml}
{req_xml}
{uniq_xml}
{len_xml}
{prec_scale_xml}
{visible_lines_xml}
{default_val_xml}
{rel_xml}
{pk_xml}
{for_xml}
</CustomField>"""

    path = f"{base_dir}/objects/{object_name}/fields"
    create_dir(path)
    with open(f"{path}/{field_name}.field-meta.xml", "w", encoding="utf-8") as f:
        f.write(field_xml)

# Create Objects and Tabs
generate_object("Course__c", "Course", "Courses", "Course Name", "Text", "Read")
generate_tab("Course__c", "Courses", "Custom49: CD/DVD")

generate_object("Student_Application__c", "Student Application", "Student Applications", "Application Number", "AutoNumber", "Private", "APP-{00000}")
generate_tab("Student_Application__c", "Student Applications", "Custom18: Form")

generate_object("Document__c", "Document", "Documents", "Document Name", "Text", "ControlledByParent")
generate_tab("Document__c", "Documents", "Custom62: Paperclip")

generate_object("Admission__c", "Admission", "Admissions", "Admission ID", "AutoNumber", "Private", "ADM-{00000}")
generate_tab("Admission__c", "Admissions", "Custom12: Circle")

# Fields for Course__c
generate_field("Course__c", "Course_Code__c", "Course Code", "Text", required=True, unique=True, length=10)
generate_field("Course__c", "Description__c", "Description", "LongTextArea", length=1000)
generate_field("Course__c", "Credits__c", "Credits", "Number", precision=2, scale=0)
generate_field("Course__c", "Capacity__c", "Capacity", "Number", required=True, precision=4, scale=0)
generate_field("Course__c", "Status__c", "Status", "Picklist", picklist_values=["Active", "Inactive"])
generate_field("Course__c", "Fees__c", "Fees", "Currency", precision=8, scale=2)

# Fields for Student_Application__c
generate_field("Student_Application__c", "First_Name__c", "First Name", "Text", required=True, length=50)
generate_field("Student_Application__c", "Last_Name__c", "Last Name", "Text", required=True, length=50)
generate_field("Student_Application__c", "Email__c", "Email", "Email", required=True)
generate_field("Student_Application__c", "Phone__c", "Phone", "Phone")
generate_field("Student_Application__c", "Date_of_Birth__c", "Date of Birth", "Date", required=True)
generate_field("Student_Application__c", "Applied_Course__c", "Applied Course", "Lookup", required=True, related_to="Course__c")
generate_field("Student_Application__c", "Application_Status__c", "Application Status", "Picklist", picklist_values=["Draft", "Submitted", "Under Review", "Approved", "Rejected"])
generate_field("Student_Application__c", "Document_Status__c", "Document Status", "Picklist", picklist_values=["Pending", "Verified", "Rejected"])
generate_field("Student_Application__c", "Admission_Status__c", "Admission Status", "Picklist", picklist_values=["Pending", "Admitted", "Waitlisted"])

# Fields for Document__c
generate_field("Document__c", "Student_Application__c", "Student Application", "MasterDetail", related_to="Student_Application__c")
generate_field("Document__c", "Document_Type__c", "Document Type", "Picklist", picklist_values=["Academic Transcript", "Identity Proof", "Address Proof", "Passport Photo"])
generate_field("Document__c", "Verification_Status__c", "Verification Status", "Picklist", picklist_values=["Pending", "Verified", "Rejected"])
generate_field("Document__c", "Rejection_Reason__c", "Rejection Reason", "Text", length=255)
generate_field("Document__c", "Verified_By__c", "Verified By", "Lookup", related_to="User")

# Fields for Admission__c
generate_field("Admission__c", "Student_Application__c", "Student Application", "Lookup", required=True, related_to="Student_Application__c")
generate_field("Admission__c", "Student_Name__c", "Student Name", "Formula", formula="Student_Application__r.First_Name__c & ' ' & Student_Application__r.Last_Name__c")
generate_field("Admission__c", "Course__c", "Course", "Lookup", required=True, related_to="Course__c")
generate_field("Admission__c", "Admission_Date__c", "Admission Date", "Date", required=True)
generate_field("Admission__c", "Enrollment_Number__c", "Enrollment Number", "Text", unique=True, length=20)
generate_field("Admission__c", "Fees_Paid__c", "Fees Paid", "Checkbox")
generate_field("Admission__c", "Student_Application_Unique_Key__c", "Student Application Unique Key", "Text", unique=True, length=255)

print("Metadata files successfully generated!")
