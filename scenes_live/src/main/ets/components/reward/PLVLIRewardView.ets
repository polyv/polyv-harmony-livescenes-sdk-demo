import { GiftDetailDataBean, PLVCommonConstants, PLVDeviceUtils, PLVHttpError, PLVI18NDataMapper, PLVJSONObject, PLVJSONUtils, PLVLiveSceneSDK, PLVToastUtils } from '@polyvharmony/live-scenes-sdk'

@Preview
@Component
export struct PLVLIRewardView {
  @Link rewardDataBeans: GiftDetailDataBean[]
  @Link rewardType: string
  rewardDialogController = new CustomDialogController({
    builder: PLVLIRewardDialog({
      rewardDataBeans: this.rewardDataBeans,
      rewardType: this.rewardType
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  })

  build() {
    Image($r('app.media.plvli_reward'))
      .width(32)
      .height(32)
      .draggable(false)
      .onClick(() => {
        this.rewardDialogController.open()
      })
  }
}

@Preview
@CustomDialog
export struct PLVLIRewardDialog {
  @Link rewardDataBeans: GiftDetailDataBean[]
  @Link rewardType: string
  @LocalStorageLink('remainingRewardPoint') remainingRewardPoint: number = 0
  controller?: CustomDialogController
  swiperRewardDataBeans: Array<GiftDetailDataBean[]> = []
  @LocalStorageLink('rewardCountSelectIndex') rewardCountSelectIndex: number = 0
  @LocalStorageLink('rewardItemSelectIndex') rewardItemSelectIndex: number = -1
  @LocalStorageLink('rewardSwiperIndex') rewardSwiperIndex: number = 0
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  goodNumArr: number[] = [1, 5, 10, 66, 88, 666]

  aboutToAppear(): void {
    const rewardDataBeanSection: GiftDetailDataBean[] = []
    for (let i = 0; i < this.rewardDataBeans.length; i++) {
      if (rewardDataBeanSection.length < 10) {
        rewardDataBeanSection.push(this.rewardDataBeans[i])
      }
      if (rewardDataBeanSection.length == 10 || i == this.rewardDataBeans.length - 1) {
        this.swiperRewardDataBeans.push([...rewardDataBeanSection])
        rewardDataBeanSection.length = 0
      }
    }
    if (this.isPointReward()) {
      this.sdk?.rewardManager.getRemainingRewardPoint()
        .then((value) => {
          this.remainingRewardPoint = value
        })
    }
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text(this.isPointReward() ? $r('app.string.plvli_reward_type_point') : $r('app.string.plvli_reward_type_cash'))
            .fontSize(16)
            .fontColor('#FFFFFF')
            .margin({ left: 10 })
          if (this.isPointReward()) {
            Text($r('app.string.plvli_reward_remain_point', this.remainingRewardPoint + ''))
              .fontSize(12)
              .fontColor('#ADADC0')
              .margin({ left: 8 })
          }
          Blank()
          Image($r('app.media.plvli_popup_close'))
            .width(34)
            .height(34)
            .objectFit(ImageFit.ScaleDown)
            .draggable(false)
            .onClick(() => {
              this.controller?.close()
            })
        }
        .justifyContent(FlexAlign.Center)
        .width(PLVCommonConstants.FULL_PERCENT)

        Swiper() {
          ForEach(this.swiperRewardDataBeans, (item: GiftDetailDataBean[], index1) => {
            Grid() {
              ForEach(item, (data: GiftDetailDataBean, index2) => {
                GridItem() {
                  Column() {
                    Image(data.getImg())
                      .width(48)
                      .height(48)
                      .objectFit(ImageFit.Contain)
                      .draggable(false)
                    Text(data.getName())
                      .margin({ top: 2 })
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .fontSize(12)
                      .textAlign(TextAlign.Center)
                      .fontColor('#D0D0D0')
                    Text() {
                      Span(this.isPointReward() ? data.price + '' : $r('app.string.plvli_commodity_free'))
                      if (this.isPointReward()) {
                        Span(data.pointUnit)
                      }
                    }
                    .margin({ top: 4 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontSize(10)
                    .textAlign(TextAlign.Center)
                    .fontColor('#ADADC0')
                  }
                  .padding({ top: 8, bottom: 8 })
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Center)
                }
                .backgroundColor(this.rewardItemSelectIndex == index1 * 10 + index2 ? '#ff3e3e4e' : '#00000000')
                .borderRadius(8)
                .onClick(() => {
                  this.rewardItemSelectIndex = index1 * 10 + index2
                })
              })
            }
            .margin({ bottom: 30 })
            .rowsTemplate('1fr 1fr')
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
          })
        }
        .index(this.rewardSwiperIndex)
        .onChange((index) => {
          this.rewardSwiperIndex = index
        })
        .height(240)
        .translate({ y: 8 })
        .loop(false)
        .autoPlay(false)
        .width(PLVCommonConstants.FULL_PERCENT)
        .indicator(
          Indicator.dot()
            .itemWidth(5)
            .itemHeight(5)
            .selectedItemWidth(5)
            .selectedItemHeight(5)
            .color('#80ffffff')
            .selectedColor(Color.White)
        )

        Row() {
          ForEach(this.goodNumArr, (value: number, index) => {
            this.rewardCountText(value + '', index)
          })
          Blank()
          Button($r('app.string.plvli_reward_text'))
            .height(32)
            .backgroundColor('#FFA611')
            .fontColor('#FFFFFF')
            .fontSize(12)
            .onClick(() => {
              if (this.rewardItemSelectIndex == -1) {
                PLVToastUtils.shortShow($r('app.string.plvli_reward_select_cash_hint'))
                return
              }
              this.handleReward(this.rewardDataBeans[this.rewardItemSelectIndex])
              this.controller?.close()
            })
        }
        .margin({ top: 6 })
        .padding({ left: 10, right: 10 })
        .width(PLVCommonConstants.FULL_PERCENT)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Start)
      }
      .padding({
        left: 6,
        right: 6,
        top: 6,
        bottom: PLVDeviceUtils.getNavigationIndicatorHeight() - 6
      })
      .justifyContent(FlexAlign.End)
      .width(PLVCommonConstants.FULL_PERCENT)
    }
    .borderRadius({
      topLeft: 12,
      topRight: 12,
      bottomLeft: 0,
      bottomRight: 0
    })
    .width(PLVCommonConstants.FULL_PERCENT)
    .backgroundColor('#cc000000')
    .backdropBlur(8)
  }

  @Builder
  rewardCountText(content: string, index: number) {
    Text(content)
      .height(24)
      .fontColor(this.rewardCountSelectIndex == index ? '#FFFFFF' : '#ADADC0')
      .fontSize(12)
      .textAlign(TextAlign.Center)
      .constraintSize({ minWidth: 36 })
      .backgroundColor(this.rewardCountSelectIndex == index ? '#ff3e3e4e' : '#ff1a1b1f')
      .borderWidth(this.rewardCountSelectIndex == index ? 1 : 0)
      .borderColor('#ffadadc0')
      .borderRadius(12)
      .margin({ right: 4 })
      .onClick(() => {
        this.rewardCountSelectIndex = index
      })
  }

  isPointReward() {
    return 'POINT' === this.rewardType
  }

  isCashReward() {
    return 'CASH' === this.rewardType
  }

  handleReward(data: GiftDetailDataBean) {
    if (this.isPointReward()) {
      this.sdk?.rewardManager.makePointReward(data.goodId, this.goodNumArr[this.rewardCountSelectIndex])
        .then((value) => {
          this.remainingRewardPoint = value
        })
        .catch((err: PLVHttpError) => {
          this.toastError(err)
        })
    } else {
      this.sdk?.rewardManager.makeGiftCashReward(data.goodId, this.goodNumArr[this.rewardCountSelectIndex])
        .catch((err: PLVHttpError) => {
          this.toastError(err)
        })
    }
  }

  toastError(err: PLVHttpError) {
    const errData = PLVJSONUtils.safeParse(err.message) as PLVJSONObject
    if (errData) {
      const errMessage = errData['message'] as string
      PLVToastUtils.shortShow(PLVI18NDataMapper.getException(errMessage) || '')
    }
  }
}