import { PLVCommonConstants, PLVLiveSceneSDK, PLVUserType } from '@polyvharmony/live-scenes-sdk'
import { Disposable, lateInit } from '@polyvharmony/media-player-sdk'
import {
  ClickType,
  ItemInfo,
  ItemType,
  photoAccessHelper,
  PhotoPickerComponent,
  PickerController,
  SelectMode
} from '@kit.MediaLibraryKit'
import { PLVSAPageDataBus } from '../../../common/PLVSAPageDataBus'

@Component
export struct PLVSAStartUpSplashImageLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly imagePickerDialog = new CustomDialogController({
    builder: PLVSAStartUpSplashImageSelectDialog({
      onSelectImage: (image: string) => {
        this.onSelectUpdateSplashImage(image)
        this.imagePickerDialog.close()
      }
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  })
  @State private splashImage: string | undefined = undefined

  aboutToAppear(): void {
    this.splashImage = this.sdk.channelData.streamerData?.splashImg
  }

  build() {
    Stack() {
      Image(this.splashImage)
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
        .backgroundColor('#4D000000')
        .objectFit(ImageFit.Contain)

      Text($r('app.string.plvsa_setting_splash_change_hint'))
        .width(PLVCommonConstants.FULL_PERCENT)
        .fontColor('#FFFFFF')
        .fontSize(10)
        .backgroundColor('#80000000')
        .textAlign(TextAlign.Center)
        .padding({
          top: 2,
          bottom: 2
        })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .borderRadius(8)
    .clip(true)
    .alignContent(Alignment.Bottom)
    .onClick(() => {
      if (this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER) {
        this.imagePickerDialog.open()
      }
    })
  }

  private async onSelectUpdateSplashImage(uri: string) {
    const remoteUrl = await this.sdk.streamerManager.updateChannelSplashImage(uri)
    this.splashImage = remoteUrl
  }

}

@CustomDialog
struct PLVSAStartUpSplashImageSelectDialog {
  onSelectImage: (image: string) => void = lateInit()
  controller: CustomDialogController = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State private readonly pickerController: PickerController = new PickerController();
  private onBackPressDisposable: Disposable | null = null

  aboutToAppear(): void {
    this.onBackPressDisposable = this.pageDataBus.onBackPressHandler.register(20, () => this.onBackPress())
  }

  build() {
    PhotoPickerComponent({
      pickerOptions: {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        selectMode: SelectMode.SINGLE_SELECT
      },
      onItemClicked: (itemInfo: ItemInfo, clickType: ClickType): boolean => {
        if (itemInfo.itemType === ItemType.CAMERA) {
          return true
        }
        return true
      },
      onSelect: (uri: string) => {
        this.onSelectImage(uri)
      },
      pickerController: this.pickerController
    })
      .width('100%')
      .height('80%')
  }

  onBackPress(): boolean {
    this.controller.close()
    return true
  }

  aboutToDisappear(): void {
    this.onBackPressDisposable?.dispose()
  }
}