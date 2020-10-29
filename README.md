# xgear
Doomsday file-based CMS on pure Perl. 
Desinged to run under any environment, no dependecies requred by core.
File::Copy used by filemanager module.

See the [project page](http://code.pta.ru/xgear) for demonstration.

## Deployment

0\.  Make sure that include_module and cgid_module are both enabled in httpd.conf
```
  LoadModule include_module modules/mod_include.so
  LoadModule cgid_module modules/mod_cgid.so
```

1\.  Upload files to you domain root directory.

2\.  Allow Server Side Includes for .html files in your .htaccess

3\.  Allow CGI for .cgi files

4\.  Allow execution of .cgi scripts and cgi-bin folder

5\.  Edit and run makeuser.cgi to extend users.txt with your account. 

6\.  Chmod 600 users.txt

7\.  Upload your files to /content

8\.  Redesign your site by changing templates in /style

## Markup Tags

1. ``` <!--xg_mod:[module name]--> [module markup] <!--/xg_mod--> ```

  These tags are used to cut bits of information from page, run the defined module
  and send previously extracted data to module as an argument. The extracted text 
  will then be replaced by the module output.
	
2. ``` <!--xg_sample:[sample name]--> [sample markup] <!--/xg_sample--> ```

  If the specified mudule needs to reuse part of markup code while it iterates 
  through multiple items, use the tag structure above. In case if module uses 
  only one sample, you can use arbitrary name.
  
3. ``` <!--xg_var:[variable name]--> ```
	
  Variable tag lets you insert arbitrary variable inside xg_mod markup.

## License

xgear is licensed under the [MIT](https://www.mit-license.org/) license for all open source applications.

## Bugs and feature requests

If you find a bug, please report it [here on Github](https://github.com/xyhtac/xgear/issues).

Guidelines for bug reports:

1. Use the GitHub issue search — check if the issue has already been reported.
2. Check if the issue has been fixed — try to reproduce it using the latest master or development branch in the repository.
3. Isolate the problem — create a reduced test case and a live example. You can use CodePen to fork any demo found on documentation to use it as a template.

A good bug report shouldn't leave others needing to chase you up for more information.
Please try to be as detailed as possible in your report.

Feature requests are welcome. Please look for existing ones and use GitHub's "reactions" feature to vote.
