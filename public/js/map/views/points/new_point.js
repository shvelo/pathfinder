var forma=require('../../forma')
  , html=require('../../forma/html');

var mPoint
  , mLayout
  , mTitle
  , mDescription
  ;

module.exports=function(model,delegate){
  mPoint=model&&model.point;

  initUI();

  return mLayout;
};

var initUI=function(){
  mTitle=forma.pageTitle('ახალი წერტილი');
  mDescription=html.p('ახალი წერტილის კოორდინატის მისაღებად დააწკაპეთ რუკაზე',{class:'text-muted'});

/////////////////////////
var txt1=forma.textField('name',{label:'დასახელება',autofocus:true, placeholder:'დატოვეთ ცარიელი ავტოშევსებისთვის'});
var sel1=forma.comboField('type',[['ქვესადგური',1],['მაღალი ძაბვის ანძა',2],['გზაჯვარედინი',111]], {label:'სახეობა'});
var txt2=forma.numberField('lat',{label:'განედი', readonly: true});
var txt3=forma.numberField('lng',{label:'გრძედი', readonly: true});
txt1.setModel(mPoint);
/////////////////////////

  mLayout=forma.verticalLayout([mTitle,mDescription,txt1,sel1,txt2,txt3]);

  mLayout.updateLocation=function(position){
    txt2.setModel(position);
    txt3.setModel(position);
  };
};
