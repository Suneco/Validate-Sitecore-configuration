# Validate Sitecore configuration
The 'ValidateSitecoreConfiguration.ps1' script validates a Sitecore instance against the recommended settings from Sitecore's "config enable/disable Excel spreadsheet" file. It will display which configuration files do or do not match the recommended setup.

The script requires input for the location of the Sitecore instance, the required server role (CM, CD, Processing, etc.) and search provider (Lucene, Solr, Azure).

To use this script the configuration spreadsheet for the required Sitecore version must be downloaded from the Sitecore documentation website (https://doc.sitecore.net). 
(E.g. https://doc.sitecore.net//~/media/CEEBD3BBE80F4E719387E4F73B76AED2.ashx?la=en for Sitecore 8.2 update 2)

This file must be altered a little to create a CSV file that can be read by the script: 
- Open the Excel, remove the first (empty) column and save it as CSV;
- Open the CSV file with a text-editor like notepad, and remove the first empty rows and the "GENERAL CONFIGURATION..." row.
- Change the header to: "ProductName;FilePath;ConfigFileName;Type;SearchProviderUsed;CD;CM;P;CMP;R" and save the file;

Update the $csvFile variable with the name and location of the CSV and run the script.