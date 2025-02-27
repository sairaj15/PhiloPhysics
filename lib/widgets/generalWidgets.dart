import 'package:ephysicsapp/globals/colors.dart';
import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';

PreferredSizeWidget themeAppBar(String title){
  return  AppBar(
        title: Text(title,style:TextStyle(color: color5),),
        backgroundColor: color1,
        iconTheme: IconThemeData(
              color: color5
            ),
       elevation: 0,
  );
}

//about us page slide
newSlide({String? imgPath,String? discription,String? title}){
  return ContentConfig(
        title: title,
        styleTitle: TextStyle(
           color: color5,
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            ),
        description:discription,
        styleDescription: TextStyle(
              color: color5,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            ),
        pathImage: imgPath,
      );
}