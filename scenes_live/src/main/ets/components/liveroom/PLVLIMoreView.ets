import { PLVCommonConstants, PLVDeviceUtils, PLVFunctionSwitchBean } from '@polyvharmony/live-scenes-sdk'
import { PLVLILanguageSwitchDialog } from './PLVLILanguageSwitchDialog'

@Preview
@Component
export struct PLVLIMoreView {
  moreDialogController = new CustomDialogController({
    builder: PLVLIMoreDialog(),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  })

  build() {
    Image($r('app.media.plvli_more'))
      .width(32)
      .height(32)
      .draggable(false)
      .onClick(() => {
        this.moreDialogController.open()
      })
  }
}

@Preview
@CustomDialog
export struct PLVLIMoreDialog {
  // 语言切换
  static readonly MORE_FUNCTION_TYPE_LANGUAGE_SWITCH = 'MORE_FUNCTION_TYPE_LANGUAGE_SWITCH'
  static readonly FUNCTION_SWITCH_LIST: PLVFunctionSwitchBean[] = [
    new PLVFunctionSwitchBean(PLVLIMoreDialog.MORE_FUNCTION_TYPE_LANGUAGE_SWITCH, $r('app.media.plvli_live_more_language_switch'), $r('app.string.plvli_live_language_switch'), true),
  ]
  functionSwitchList = PLVLIMoreDialog.FUNCTION_SWITCH_LIST
  controller?: CustomDialogController
  languageSwitchDialogController = new CustomDialogController({
    builder: PLVLILanguageSwitchDialog(),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  })

  build() {
    Stack() {
      Column() {
        Row() {
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
        .width(PLVCommonConstants.FULL_PERCENT)

        Grid() {
          ForEach(this.functionSwitchList, (data: PLVFunctionSwitchBean, index) => {
            GridItem() {
              Column() {
                Image(data.imageResource ? data.imageResource : data.icon)
                  .width(32)
                  .height(32)
                  .draggable(false)
                Text(data.name)
                  .margin({ top: 10 })
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .fontSize(12)
                  .textAlign(TextAlign.Center)
                  .fontColor('#CDCDCD')
              }
              .onClick(() => {
                this.handleGridItemClick(data)
                this.controller?.close()
              })
            }
            .height(PLVCommonConstants.FULL_PERCENT)
          })
        }
        .rowsGap(4)
        .columnsGap(4)
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .height(0)
        .layoutWeight(1)
      }
      .padding({
        left: 6,
        right: 6,
        top: 6,
        bottom: PLVDeviceUtils.getNavigationIndicatorHeight() - 6
      })
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
    }
    .borderRadius({
      topLeft: 12,
      topRight: 12,
      bottomLeft: 0,
      bottomRight: 0
    })
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(130)
    .backgroundColor('#cc000000')
    .backdropBlur(8)
  }

  handleGridItemClick(data: PLVFunctionSwitchBean) {
    switch (data.type) {
      case PLVLIMoreDialog.MORE_FUNCTION_TYPE_LANGUAGE_SWITCH:
        this.handleLanguageClick()
        break
      default:
        break
    }
  }

  handleLanguageClick() {
    this.languageSwitchDialogController.open()
  }
}