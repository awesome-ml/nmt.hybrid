function [grad_scores] = normLayerBackprop(grad_alignWeights, alignWeights, mask, params)
  %% from grad_alignWeights -> grad_scores
  % alignWeights a = softmax(scores)
  % Let's derive per indices grad align weight w.r.t scores
  %   der a_i / der s_j = der exp(s_i) / sum_k (exp(s_k)) / der s_j =
  %     (1/sum) * (der exp(s_i) / der s_j) - (exp(s_i)/sum^2)*exp(s_j) =
  %      a_i*I{i==j} - a_i*_a_j
  %
  % Now let's try to optimize the vector grad for a single example i: 
  %   grad_score_i = (diag(a_i) - a_i*a_i')*grad_a_i 
  %                = a_i.*grad_a_i - a_i*(a_i'*grad_a_i)
  %                = a_i.*grad_a_i - a_i*alpha_i
  % multiple examples: alpha = sum(a.*grad_a, 1) % 1*curBatchSize
  %     grad_scores = a.*grad - bsxfun(@times, a, alpha)
  % tmpResult = alignWeights.*grad_alignWeights; % numAttnPositions * curBatchSize
  
  %if ~isequal(size(alignWeights), size(grad_alignWeights))
  %  params
  %  size(alignWeights)
  %  size(grad_alignWeights)
  %end
  
  % assert
%   if params.assert
%     assert(sum(sum(abs(alignWeights(mask==0))))==0);
%     assert(sum(sum(abs(grad_alignWeights(mask==0))))==0);
%   end
  
  alignWeights = alignWeights.*mask;
  tmpResult = alignWeights.*grad_alignWeights; % numAttnPositions * curBatchSize
  grad_scores = tmpResult - bsxfun(@times, alignWeights, sum(tmpResult, 1));
    
  if params.assert
    % compute grad_scores in a different way
    grad_scores1 = zeroMatrix(size(grad_scores), params.isGPU, params.dataType);
    for ii=1:params.curBatchSize
      grad_scores1(:, ii) = (diag(alignWeights(:, ii))-alignWeights(:, ii)*alignWeights(:, ii)')*grad_alignWeights(:, ii);
    end
    assert(sum(sum(abs(grad_scores-grad_scores1)))<1e-10);
  end
end
