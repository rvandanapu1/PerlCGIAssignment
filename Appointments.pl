#!/usr/bin/perl

use DBI;
use JSON;
#use Hash::Merge qw( merge );
use CGI;

my $cgi = CGI->new;

my $driver = "mysql"; 
my $database = "Appointments";
my $dsn = "DBI:$driver:database=$database";
my $userid = "root";
my $password = "123";
my %merged_hash;
$i=0;
my $dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;





#form Handling post Request

local ($buffer, @pairs, $pair, $name, $value, %FORM);
# Read in text
$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;

if ($ENV{'REQUEST_METHOD'} eq "POST"){
   read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
}else {
   $buffer = $ENV{'QUERY_STRING'};
}

# Split information into name/value pairs
@pairs = split(/&/, $buffer);

foreach $pair (@pairs) {
   ($name, $value) = split(/=/, $pair);
   $value =~ tr/+/ /;
   $value =~ s/%(..)/pack("C", hex($1))/eg;
   $FORM{$name} = $value;
}

$date = $FORM{date};
$time  = $FORM{time};
$description =  $FORM{desc};

$insert_query="INSERT INTO appointments_list(date,time,description) values(?,?,?)";

my $search_data=$cgi->param('keyword');

my $search_query;

if($search_data){
  #means Search Query
  $search_query="SELECT * FROM  appointments_list where description like \'\%$search_data\%\'";


}

else{

  #normal Query
   $search_query="SELECT * FROM  appointments_list";

}


if(defined $cgi->param('keyword')){


print $cgi->header('application/json;charset=UTF-8');

#find the ajax data for search





my $sth = $dbh->prepare($search_query);
$sth->execute() or die $DBI::errstr;

while (my @row = $sth->fetchrow_array()) {
   my ($first_name, $last_name,$description ) = @row;
   my %rec_hash = ('date'=>$first_name,'time'=>$last_name,'description'=>$description);
 
  my $json = encode_json \%rec_hash;
 @result_arr[$i++]=$json;

 
}

%ans="";
for($j=0;$j<scalar @result_arr;$j++){
  %ans=(%ans,($j=>@result_arr[$j]));
}
my $json_res=encode_json \%ans;

print $json_res;




$sth->finish();



}

#form Handling post Request Ended

elsif($date && $time && $description)
{

#do the validation here

  my $statment = $dbh->prepare($insert_query);
$statment->execute($date,$time,$description) or die $DBI::errstr;



  


  #see  whether it is Insert Data Query
  #produce the HTML

  print "Content-type:text/html\r\n\r\n";

  print <<END_HTML;
    <html>
  <head>  

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"/>
    <link rel="stylesheet" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css" type="text/css" media="all">
    <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
    <script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>
 
  </head> 
  <body>

    <div class="container-fluid">
      <div class="row">
        <div class="col-md-12 col-lg-12 col-sm-12 error-msg ">

          <p class="">$error_msg</p>
        </div>
      </div>
      <div class="row new-appnt-btn">
        <div class="col-md-12 col-lg-12 col-sm-12 new-button ">
          <button class="btn btn-success new">New</button>
        </div>

      </div>
      <div class="row">


        <div class="col-md-8 col-lg-8 col-sm-8  hide-it" id="newAppointee">
          <form action="sampleRead.pl" method="GET">
            <button type="submit" class="btn btn-primary add">Add</button>
            <button type="reset" class="btn btn-danger cancel">Cancel</button>

          <div class="form-fields-appn">
            <div class="addfields">
              <label>DATE</label>
              <input type="text" id="from" class="form-control" name="date" placeholder="Add Appointment Date" required/>
            </div>
            <div class="addfields">
              <label>TIME</label>
              <input type="text" class="form-control" name="time" placeholder="Add Appointment Time" required/>
            </div>
            <div class="addfields">
              <label>DESCRIPTION</label>
              <input type="text" class="form-control" name="desc" placeholder="Add Appointment Description" required/>
            </div>
          </div>
          </form>
          </div>
      </div>


        <div class="row">
          <div class="col-md-8 col-lg-8 col-sm-8">
          <input type="text" class="form-control search-area" placeholder="Enter text to search"/>
        </div>
        <div class="col-md-4 col-sm-4 col-lg-4">
          <button class="btn btn-primary search-box">Search</button>
        </div>
        </div>
        <div class="row">
          <div class="col-md-12 col-lg-12 col-sm-12 appointments-area">
            <table class="table table-bordered">
              <thead>
                <tr>
                  <th>DATE</th>
                  <th>TIME</th>
                  <th>DESCRIPTION</th>
                </tr>
              </thead>
              <tbody>
              </tbody>
              


      

            </table>

          </div>
        </div>

      </div>
    



  </body>
  <style>
  .hide-it{
    display:none;
  }
  .search-box{
    display: inline;
  }
  .row{
    margin-top:15px;
  }
  #newAppointee{
    border:1px solid black;
    padding:20px;
  }
  .form-fields-appn{
    padding:20px;
  }
  .addfields{
    margin-top: 10px;
  }
  </style>
  <script>
    jQuery(document).ready(function(){



    var dateToday = new Date();
    var dates = jQuery("#from").datepicker({
    defaultDate: "+1w",
    changeMonth: true,
    numberOfMonths: 1,
    minDate: dateToday,
    onSelect: function(selectedDate) {
        var option = this.id == "from" ? "minDate" : "maxDate",
            instance = jQuery(this).data("datepicker"),
            date = jQuery.datepicker.parseDate(instance.settings.dateFormat || jQuery.datepicker._defaults.dateFormat, selectedDate, instance.settings);
        dates.not(this).datepicker("option", option, date);
    }
});



      //do a ajax call to get all Appoinments here

      var nodata={
        keyword:''
      };

       getAppointments(nodata);

      function getAppointments(data){


        jQuery.ajax({


        url:'/sampleRead.pl',
        data:data,
        success:function(result){
          


          
          for(var key in result){
            if(key && key!==null){
              var temp=JSON.parse(result[key]);
              jQuery(".appointments-area table tbody").append("<tr><td>"+temp.date+"</td><td>"+temp.time+"</td><td>"+temp.description+"</td></tr>");

            }
          }

        }

      })





      }



      
      //Click Event hander for search 

      //Click Event handler for New Button

      jQuery(".new").on('click',function(){
        jQuery("#newAppointee").removeClass("hide-it");
        jQuery(".new-appnt-btn").hide();
      });




      //Handle the cancel event
      jQuery(".cancel").on('click',function(){

        //hide the form again
        jQuery("#newAppointee").addClass("hide-it");
        jQuery(".new-appnt-btn").show();

      });

      jQuery(".search-box").on('click',function(){

        //Do a Ajax to reload the Search Result

        var data={

          keyword:jQuery(".search-area").val()
        };

        


        jQuery.ajax({

        url:'/sampleRead.pl',
        data:data,
        success:function(result){
          

          //first clear the previous html 
          jQuery(".appointments-area table tbody").html('');
          
          
          var ind=0;
          
          for(var key in result){
            
            if(key && key!==null && key!==""){
              ind=1;
              var temp=JSON.parse(result[key]);
              jQuery(".appointments-area table tbody").append("<tr><td>"+temp.date+"</td><td>"+temp.time+"</td><td>"+temp.description+"</td></tr>");

            }

          }
          if(ind===0){


              jQuery(".appointments-area table tbody").html("<b>No Results found</b>")

          
          }

        }

      })



      });

      

      //Handle the Add Button



    });
  </script>

</html>

END_HTML

}

elsif($date || $time || $description){


  print "Content-type:text/html\r\n\r\n";

  print <<END_HTML;
    <html>
  <head>  

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"/>
    <link rel="stylesheet" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css" type="text/css" media="all">
    <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
    <script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>
  </head> 
  <body>

    <div class="container-fluid">
      <div class="row">
        <div class="col-md-12 col-lg-12 col-sm-12 error-msg ">

          <p class="alert alert-danger">Please fill the Required Values</p>
        </div>
      </div>
      <div class="row new-appnt-btn">
        <div class="col-md-12 col-lg-12 col-sm-12 new-button ">
          <button class="btn btn-success new">New</button>
        </div>

      </div>
      <div class="row">


        <div class="col-md-8 col-lg-8 col-sm-8  hide-it" id="newAppointee">
          <form action="sampleRead.pl" method="GET">
            <button type="submit" class="btn btn-primary add">Add</button>
            <button type="reset" class="btn btn-danger cancel">Cancel</button>

          <div class="form-fields-appn">
            <div class="addfields">
              <label>DATE</label>
              <input type="text" id="from" class="form-control" name="date" placeholder="Add Appointment Date" required/>
            </div>
            <div class="addfields">
              <label>TIME</label>
              <input type="text" class="form-control" name="time" placeholder="Add Appointment Time" required/>
            </div>
            <div class="addfields">
              <label>DESCRIPTION</label>
              <input type="text" class="form-control" name="desc" placeholder="Add Appointment Description" required/>
            </div>
          </div>
          </form>
          </div>
      </div>


        <div class="row">
          <div class="col-md-8 col-lg-8 col-sm-8">
          <input type="text" class="form-control search-area" placeholder="Enter text to search"/>
        </div>
        <div class="col-md-4 col-sm-4 col-lg-4">
          <button class="btn btn-primary search-box">Search</button>
        </div>
        </div>
        <div class="row">
          <div class="col-md-12 col-lg-12 col-sm-12 appointments-area">
            <table class="table table-bordered">
              <thead>
                <tr>
                  <th>DATE</th>
                  <th>TIME</th>
                  <th>DESCRIPTION</th>
                </tr>
              </thead>
              <tbody>
              </tbody>
              


      

            </table>

          </div>
        </div>

      </div>
    



  </body>
  <style>
  .hide-it{
    display:none;
  }
  .search-box{
    display: inline;
  }
  .row{
    margin-top:15px;
  }
  #newAppointee{
    border:1px solid black;
    padding:20px;
  }
  .form-fields-appn{
    padding:20px;
  }
  .addfields{
    margin-top: 10px;
  }
  </style>
  <script>


    

    jQuery(document).ready(function(){

    var dateToday = new Date();
    var dates = jQuery("#from").datepicker({
    defaultDate: "+1w",
    changeMonth: true,
    numberOfMonths: 1,
    minDate: dateToday,
    onSelect: function(selectedDate) {
        var option = this.id == "from" ? "minDate" : "maxDate",
            instance = jQuery(this).data("datepicker"),
            date = jQuery.datepicker.parseDate(instance.settings.dateFormat || jQuery.datepicker._defaults.dateFormat, selectedDate, instance.settings);
        dates.not(this).datepicker("option", option, date);
    }
});


      //do a ajax call to get all Appoinments here



      var nodata={
        keyword:''
      };

      jQuery.ajax({

        url:'/sampleRead.pl',
        data:nodata,
        success:function(result){
          


          
          for(var key in result){
            if(key && key!==null){
              var temp=JSON.parse(result[key]);
              jQuery(".appointments-area table tbody").append("<tr><td>"+temp.date+"</td><td>"+temp.time+"</td><td>"+temp.description+"</td></tr>");

            }
          }

        }

      })


      //Click Event hander for search 

      //Click Event handler for New Button

      jQuery(".new").on('click',function(){
        jQuery("#newAppointee").removeClass("hide-it");
        jQuery(".new-appnt-btn").hide();
      });




      //Handle the cancel event
      jQuery(".cancel").on('click',function(){

        //hide the form again
        jQuery("#newAppointee").addClass("hide-it");
        jQuery(".new-appnt-btn").show();

      });

      jQuery(".search-box").on('click',function(){

        //Do a Ajax to reload the Search Result

        var data={

          keyword:jQuery(".search-area").val()
        };


        jQuery.ajax({

        url:'/sampleRead.pl',
        data:data,
        success:function(result){
          

          //first clear the previous html 
          jQuery(".appointments-area table tbody").html('');
          
          
          var ind=0;
          
          for(var key in result){
            
            if(key && key!==null && key!==""){
              ind=1;
              var temp=JSON.parse(result[key]);
              jQuery(".appointments-area table tbody").append("<tr><td>"+temp.date+"</td><td>"+temp.time+"</td><td>"+temp.description+"</td></tr>");

            }

          }
          if(ind===0){


              jQuery(".appointments-area table tbody").html("<b>No Results found</b>")

          
          }

        }

      })



      });

      

      //Handle the Add Button



    });
  </script>

</html>

END_HTML




}
else{
   print "Content-type:text/html\r\n\r\n";

  print <<END_HTML;
    <html>
  <head>  

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"/>
    <link rel="stylesheet" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css" type="text/css" media="all">
    <script src="https://code.jquery.com/jquery-1.12.4.js"></script>
    <script type="text/javascript" src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
    <script type="text/javascript" src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>
  </head> 
  <body>

    <div class="container-fluid">
      <div class="row">
        <div class="col-md-12 col-lg-12 col-sm-12 error-msg ">

          <p class=""></p>
        </div>
      </div>
      <div class="row new-appnt-btn">
        <div class="col-md-12 col-lg-12 col-sm-12 new-button ">
          <button class="btn btn-success new">New</button>
        </div>

      </div>
      <div class="row">


        <div class="col-md-8 col-lg-8 col-sm-8  hide-it" id="newAppointee">
          <form action="sampleRead.pl" method="GET">
            <button type="submit" class="btn btn-primary add">Add</button>
            <button type="reset" class="btn btn-danger cancel">Cancel</button>

          <div class="form-fields-appn">
            <div class="addfields">
              <label>DATE</label>
              <input type="text" id="from" class="form-control" name="date" placeholder="Add Appointment Date" required/>
            </div>
            <div class="addfields">
              <label>TIME</label>
              <input type="text" class="form-control" name="time" placeholder="Add Appointment Time" required/>
            </div>
            <div class="addfields">
              <label>DESCRIPTION</label>
              <input type="text" class="form-control" name="desc" placeholder="Add Appointment Description" required/>
            </div>
          </div>
          </form>
          </div>
      </div>


        <div class="row">
          <div class="col-md-8 col-lg-8 col-sm-8">
          <input type="text" class="form-control search-area" placeholder="Enter text to search"/>
        </div>
        <div class="col-md-4 col-sm-4 col-lg-4">
          <button class="btn btn-primary search-box">Search</button>
        </div>
        </div>
        <div class="row">
          <div class="col-md-12 col-lg-12 col-sm-12 appointments-area">
            <table class="table table-bordered">
              <thead>
                <tr>
                  <th>DATE</th>
                  <th>TIME</th>
                  <th>DESCRIPTION</th>
                </tr>
              </thead>
              <tbody>
              </tbody>
              


      

            </table>

          </div>
        </div>

      </div>
    



  </body>
  <style>
  .hide-it{
    display:none;
  }
  .search-box{
    display: inline;
  }
  .row{
    margin-top:15px;
  }
  #newAppointee{
    border:1px solid black;
    padding:20px;
  }
  .form-fields-appn{
    padding:20px;
  }
  .addfields{
    margin-top: 10px;
  }
  </style>
  <script>


    

    jQuery(document).ready(function(){

    var dateToday = new Date();
    var dates = jQuery("#from").datepicker({
    defaultDate: "+1w",
    changeMonth: true,
    numberOfMonths: 1,
    minDate: dateToday,
    onSelect: function(selectedDate) {
        var option = this.id == "from" ? "minDate" : "maxDate",
            instance = jQuery(this).data("datepicker"),
            date = jQuery.datepicker.parseDate(instance.settings.dateFormat || jQuery.datepicker._defaults.dateFormat, selectedDate, instance.settings);
        dates.not(this).datepicker("option", option, date);
    }
});


      //do a ajax call to get all Appoinments here



      var nodata={
        keyword:''
      };

      jQuery.ajax({

        url:'/sampleRead.pl',
        data:nodata,
        success:function(result){
          


          
          for(var key in result){
            if(key && key!==null){
              var temp=JSON.parse(result[key]);
              jQuery(".appointments-area table tbody").append("<tr><td>"+temp.date+"</td><td>"+temp.time+"</td><td>"+temp.description+"</td></tr>");

            }
          }

        }

      })


      //Click Event hander for search 

      //Click Event handler for New Button

      jQuery(".new").on('click',function(){
        jQuery("#newAppointee").removeClass("hide-it");
        jQuery(".new-appnt-btn").hide();
      });




      //Handle the cancel event
      jQuery(".cancel").on('click',function(){

        //hide the form again
        jQuery("#newAppointee").addClass("hide-it");
        jQuery(".new-appnt-btn").show();

      });

      jQuery(".search-box").on('click',function(){

        //Do a Ajax to reload the Search Result

        var data={

          keyword:jQuery(".search-area").val()
        };


        jQuery.ajax({

        url:'/sampleRead.pl',
        data:data,
        success:function(result){
          

          //first clear the previous html 
          jQuery(".appointments-area table tbody").html('');
          
          
          var ind=0;
          
          for(var key in result){
            
            if(key && key!==null && key!==""){
              ind=1;
              var temp=JSON.parse(result[key]);
              jQuery(".appointments-area table tbody").append("<tr><td>"+temp.date+"</td><td>"+temp.time+"</td><td>"+temp.description+"</td></tr>");

            }

          }
          if(ind===0){


              jQuery(".appointments-area table tbody").html("<b>No Results found</b>")

          
          }

        }

      })



      });

      

      //Handle the Add Button



    });
  </script>

</html>

END_HTML

}




