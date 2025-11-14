import {
  PLVCommonConstants,
  PLVLazyValue,
  PLVLiveSceneSDK,
  PLVNodeController,
  PLVPPTStatus,
  PLVPPTWeb,
  PLVPPTWebController
} from '@polyvharmony/live-scenes-sdk';
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';
import { lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWWatermarkLayout } from '../../player/watermark/PLVLWWatermarkLayout';

@Component
export struct PLVLWPPTView {
  @State viewData: PPTViewData = lateInit()
  webController: PLVLazyValue<PLVPPTWebController | undefined> = new PLVLazyValue(() => {
    return this.viewData.sdk?.webControllerManager.createPPTWebController() as PLVPPTWebController
  })
  private observers: MutableObserver[] = []
  @State isPPTToMainScreen: boolean = false

  aboutToAppear(): void {
    this.onPPTData()
    this.onLayoutData()
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    RelativeContainer() {
      PLVPPTWeb({
        controller: this.webController.get()
      })
        .enabled(this.isPPTToMainScreen)
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)

      PLVLWWatermarkLayout({
        sdk: this.viewData.sdk
      })
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
    }
  }

  onPPTData() {
    this.webController.get()?.eventNotify.on('switchPPTLocation', (isPPTToMainScreen: boolean) => {
      this.viewData.layoutDataBus?.isPPTToMainScreen.setValue(isPPTToMainScreen)
    }, this)
    this.webController.get()?.eventNotify.on('onPPTStatusChange', (status: PLVPPTStatus) => {
      this.viewData.layoutDataBus?.pptStatus.setValue(status)
    })
  }

  onLayoutData() {
    watchStates(() => {
      this.isPPTToMainScreen = this.viewData.layoutDataBus?.isPPTToMainScreen.value ?? false
    }).pushTo(this.observers)
    this.viewData.layoutDataBus?.onChangePPTPage.observe((value)=>{
      this.webController.get()?.changePPTPage(value)
    }).pushTo(this.observers)
  }
}

export class PPTViewData {
  sdk: PLVLiveSceneSDK
  layoutDataBus?: PLVLWLayoutDataBus

  constructor(sdk: PLVLiveSceneSDK, layoutDataBus?: PLVLWLayoutDataBus) {
    this.sdk = sdk
    this.layoutDataBus = layoutDataBus
  }
}

@Builder
export function pptViewBuilder(data: PPTViewData) {
  PLVLWPPTView({ viewData: data })
}

export function createPPTViewNodeController(isShow: boolean, data: PPTViewData): PLVNodeController {
  return new PLVNodeController({
    name: 'pptViewNodeController_' + data.sdk.uniqueId,
    isShow: isShow,
    wrapBuilder: wrapBuilder(pptViewBuilder),
    params: data
  })
}