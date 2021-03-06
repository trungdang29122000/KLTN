import 'package:app_kltn_trunghoan/bloc/product_banner/product_home_bloc.dart';

import 'package:app_kltn_trunghoan/models/product_model.dart';
import 'package:app_kltn_trunghoan/ui/home/widgets/product_recommend_card.dart';
import 'package:app_kltn_trunghoan/ui/home/widgets/product_recommend_card_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_kltn_trunghoan/helpers/sizer_custom/sizer.dart';

class ProductRecommendList extends StatelessWidget {
  const ProductRecommendList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductHomeBloc, ProductHomeState>(
      builder: (context, state) {
        if (state is GetDoneProductHome) {
          List<ProductModel>? products = state.props[0] as List<ProductModel>?;
          if (products != null) {
            return Container(
              height: 70.sp,
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.sp),
                itemCount: products.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ProductRecommendCard(
                    productModel: products[index],
                  );
                },
              ),
            );
          }
        }
        return Container(
          height: 70.sp,
          child: ListView.builder(
            physics: BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.sp),
            itemCount: 4,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return ProductRecommendCardShimmer();
            },
          ),
        );
      },
    );
  }
}
