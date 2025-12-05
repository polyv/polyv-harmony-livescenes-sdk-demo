import { PLVLWPPTNodeContainer } from '../../ppt/node/PLVLWPPTNodeContainer';

@Component
export struct PLVLWLinkMicListItemPpt {

  build() {
    Stack() {
      PLVLWPPTNodeContainer()
    }
    .width(90)
    .height(90)
    .borderRadius(8)
  }

}